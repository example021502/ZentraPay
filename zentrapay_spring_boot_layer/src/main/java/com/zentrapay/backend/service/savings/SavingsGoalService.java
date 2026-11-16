package com.zentrapay.backend.service.savings;

import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.ActivityDTO;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.CreateGoalRequest;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.DeletedGoalDTO;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.GoalDTO;
import com.zentrapay.backend.entity.SavingsGoalModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.entity.UserSavingsModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.SavingsGoalRepository;
import com.zentrapay.backend.repository.TransactionRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.repository.UserSavingsRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.payment.LedgerOperations;
import com.zentrapay.backend.service.payment.TransactionRecorder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.UUID;

/**
 * Savings goals ("Save Goal"): the user creates a goal, then moves money from a wallet account into
 * it and back. Every move is one all-or-nothing database step: wallet debit/credit, the
 * {@code transactions} row (SAVINGS_DEPOSIT / SAVINGS_WITHDRAWAL), its ledger entry, the goal's new
 * total and the {@code user_savings} line that feeds the ZGrow "Overall Savings" figure.
 *
 * <p>A goal is always in ONE currency (the wallet account it is funded from). When a move is refused
 * (not enough money, goal closed ...) the attempt is still saved as a FAILED transaction so the
 * history shows it.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SavingsGoalService {

    private static final String AUTO_REF_PREFIX = "SAV-AUTO-";

    private final SavingsGoalRepository goalRepository;
    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final UserSavingsRepository userSavingsRepository;
    private final LedgerOperations ledgerOperations;
    private final TransactionRecorder transactionRecorder;
    private final TransactionTemplate tx;

    // ------------------------------------------------------------------ reads

    @Transactional(readOnly = true)
    public List<GoalDTO> myGoals(UUID userId) {
        return goalRepository.findByUserIdOrderByCreatedAtDesc(userId).stream().map(SavingsGoalService::toDto).toList();
    }

    // ----------------------------------------------------------------- writes

    /**
     * Creates a goal and, when {@code initialDeposit} is given, funds it from the wallet right away.
     */
    public GoalDTO create(UUID userId, CreateGoalRequest req) {
        UserModel user = activeUser(userId);
        String name = req.savingsName() == null ? "" : req.savingsName().trim();
        if (name.isEmpty() || name.length() > 120) {
            throw new IllegalArgumentException("Give your goal a name (up to 120 characters)");
        }
        String currency = req.currencyCode().trim().toUpperCase();
        BigDecimal target = req.targetAmount() == null ? null : money(req.targetAmount());
        if (target != null && target.signum() <= 0) {
            throw new IllegalArgumentException("The target amount must be greater than zero");
        }
        if (req.targetDate() != null && !req.targetDate().isAfter(LocalDate.now())) {
            throw new IllegalArgumentException("The target date must be in the future");
        }
        BigDecimal initial = req.initialDeposit() == null ? BigDecimal.ZERO : money(req.initialDeposit());
        if (initial.signum() < 0) {
            throw new IllegalArgumentException("The first deposit cannot be negative");
        }
        // The goal can only be funded from a wallet account in its currency, so that account must exist
        requireAccount(userId, currency);

        SavingsGoalModel goal = new SavingsGoalModel();
        goal.setUserId(userId);
        goal.setGoalName(name);
        goal.setCurrencyCode(currency);
        goal.setTargetAmount(target);
        goal.setTargetDate(req.targetDate());
        goal.setDescription(clean(req.description()));
        SavingsGoalModel saved = goalRepository.save(goal);
        log.info("Savings goal {} created for user {}", saved.getGoalId(), userId);

        if (initial.signum() > 0) {
            try {
                return deposit(userId, saved.getGoalId(), initial);
            } catch (RuntimeException e) {
                // The goal itself exists (empty); the first deposit was refused and is recorded by deposit()
                log.warn("Savings goal {} created but the first deposit failed: {}", saved.getGoalId(), e.getMessage());
                throw e;
            }
        }
        return toDto(saved);
    }

    /**
     * Moves {@code amount} from the user's wallet account into the goal.
     */
    public GoalDTO deposit(UUID userId, UUID goalId, BigDecimal rawAmount) {
        return deposit(userId, goalId, rawAmount, false);
    }

    /**
     * {@code auto} = the scheduled save (shown as "Auto-save" in the activity list), not a tap by the user.
     */
    private GoalDTO deposit(UUID userId, UUID goalId, BigDecimal rawAmount, boolean auto) {
        UserModel user = activeUser(userId);
        BigDecimal amount = positive(rawAmount);
        SavingsGoalModel peek = ownedGoal(userId, goalId);
        TransactionModel attempt = draft(user, peek, Datatypes.TransactionType.SAVINGS_DEPOSIT, amount, auto);
        try {
            SavingsGoalModel result = tx.execute(status -> {
                SavingsGoalModel goal = goalRepository.findOwnedForUpdate(goalId, userId)
                        .orElseThrow(() -> new ResourceNotFoundException("Savings goal not found"));
                if ("CLOSED".equals(goal.getStatus())) {
                    throw new IllegalArgumentException("This goal is closed");
                }
                if (isFrozen(goal, LocalDateTime.now())) {
                    throw new IllegalArgumentException("This goal is frozen until "
                            + FROZEN_FORMAT.format(goal.getFrozenUntil()) + ". Unfreeze it to save again.");
                }
                FiatAccountModel account = requireAccount(userId, goal.getCurrencyCode());
                if (!"ACTIVE".equalsIgnoreCase(account.getStatus())) {
                    throw new IllegalArgumentException("Your " + goal.getCurrencyCode() + " account is " + account.getStatus() + " at the moment");
                }
                if (account.getBalance().compareTo(amount) < 0) {
                    throw new IllegalArgumentException("Insufficient balance. Please top up your " + goal.getCurrencyCode() + " account first");
                }
                TransactionModel txn = ledgerOperations.debitInternal(attempt, account,
                        (auto ? "Auto-saved to goal: " : "Saved to goal: ") + goal.getGoalName(),
                        auto ? "Auto-save done" : "Money saved",
                        goal.getCurrencyCode() + " " + amount.toPlainString() + " was added to your goal \"" + goal.getGoalName() + "\".");

                goal.setSavedAmount(goal.getSavedAmount().add(amount));
                refreshStatus(goal);
                goalRepository.save(goal);
                userSavingsRepository.save(UserSavingsModel.builder()
                        .userId(userId).currencyCode(goal.getCurrencyCode()).amount(amount)
                        .source(Datatypes.SavingsSource.MILESTONE).referenceId(goal.getGoalId())
                        .note(truncate((auto ? "Auto-save, goal: " : "Goal: ") + goal.getGoalName())).build());
                log.info("Savings: {} {} into goal {} (txn {})", amount, goal.getCurrencyCode(), goal.getGoalId(), txn.getTransactionId());
                return goal;
            });
            return toDto(result);
        } catch (RuntimeException e) {
            transactionRecorder.recordFailure(attempt, reasonOf(e));
            throw e;
        }
    }

    /**
     * Moves {@code amount} from the goal back to the user's wallet account.
     */
    public GoalDTO withdraw(UUID userId, UUID goalId, BigDecimal rawAmount) {
        UserModel user = activeUser(userId);
        BigDecimal amount = positive(rawAmount);
        SavingsGoalModel peek = ownedGoal(userId, goalId);
        TransactionModel attempt = draft(user, peek, Datatypes.TransactionType.SAVINGS_WITHDRAWAL, amount, false);
        try {
            SavingsGoalModel result = tx.execute(status -> {
                SavingsGoalModel goal = goalRepository.findOwnedForUpdate(goalId, userId)
                        .orElseThrow(() -> new ResourceNotFoundException("Savings goal not found"));
                if (goal.getSavedAmount().compareTo(amount) < 0) {
                    throw new IllegalArgumentException("You only have " + goal.getCurrencyCode() + " "
                            + goal.getSavedAmount().setScale(2, RoundingMode.HALF_UP).toPlainString() + " saved in this goal");
                }
                FiatAccountModel account = requireAccount(userId, goal.getCurrencyCode());
                TransactionModel txn = ledgerOperations.creditInternal(attempt, account,
                        "Withdrawn from goal: " + goal.getGoalName(), "Savings withdrawn",
                        goal.getCurrencyCode() + " " + amount.toPlainString() + " was moved from your goal \"" + goal.getGoalName() + "\" to your wallet.");

                goal.setSavedAmount(goal.getSavedAmount().subtract(amount));
                refreshStatus(goal);
                goalRepository.save(goal);
                userSavingsRepository.save(UserSavingsModel.builder()
                        .userId(userId).currencyCode(goal.getCurrencyCode()).amount(amount.negate())
                        .source(Datatypes.SavingsSource.MILESTONE).referenceId(goal.getGoalId())
                        .note(truncate("Withdrawn from goal: " + goal.getGoalName())).build());
                log.info("Savings: {} {} out of goal {} (txn {})", amount, goal.getCurrencyCode(), goal.getGoalId(), txn.getTransactionId());
                return goal;
            });
            return toDto(result);
        } catch (RuntimeException e) {
            transactionRecorder.recordFailure(attempt, reasonOf(e));
            throw e;
        }
    }

    // ------------------------------------------------------------ freeze / auto-save / delete

    /**
     * Stops all saving into the goal (manual and automatic) for 1 to 7 days. Withdrawing stays possible.
     */
    public GoalDTO freeze(UUID userId, UUID goalId, int days) {
        if (days < 1 || days > MAX_FREEZE_DAYS) {
            throw new IllegalArgumentException("A goal can be frozen for 1 to " + MAX_FREEZE_DAYS + " days");
        }
        ownedGoal(userId, goalId);
        return toDto(tx.execute(status -> {
            SavingsGoalModel goal = lockedGoal(userId, goalId);
            LocalDateTime now = LocalDateTime.now();
            if ("COMPLETED".equals(goal.getStatus()) || "CLOSED".equals(goal.getStatus())) {
                throw new IllegalArgumentException("This goal has already reached its target, so there is nothing to freeze");
            }
            if (isFrozen(goal, now)) {
                // No extending: a freeze never adds up to more than a week
                throw new IllegalArgumentException("This goal is already frozen until "
                        + FROZEN_FORMAT.format(goal.getFrozenUntil()) + ". Unfreeze it first to choose a new period.");
            }
            goal.setFrozenUntil(now.plusDays(days));
            log.info("Savings goal {} frozen for {} day(s) by user {}", goalId, days, userId);
            return goalRepository.save(goal);
        }));
    }

    /**
     * Ends a freeze early. Unfreezing a goal that is not frozen changes nothing.
     */
    public GoalDTO unfreeze(UUID userId, UUID goalId) {
        ownedGoal(userId, goalId);
        return toDto(tx.execute(status -> {
            SavingsGoalModel goal = lockedGoal(userId, goalId);
            goal.setFrozenUntil(null);
            log.info("Savings goal {} unfrozen by user {}", goalId, userId);
            return goalRepository.save(goal);
        }));
    }

    /**
     * Turns on (or changes) the automatic save: {@code amount} every day / week / month, first one a full period from now.
     */
    public GoalDTO setAutoSave(UUID userId, UUID goalId, BigDecimal rawAmount, String rawFrequency) {
        BigDecimal amount = positive(rawAmount);
        Frequency frequency = Frequency.parse(rawFrequency);
        ownedGoal(userId, goalId);
        return toDto(tx.execute(status -> {
            SavingsGoalModel goal = lockedGoal(userId, goalId);
            if ("COMPLETED".equals(goal.getStatus()) || "CLOSED".equals(goal.getStatus())) {
                throw new IllegalArgumentException("This goal has already reached its target");
            }
            requireAccount(userId, goal.getCurrencyCode());
            goal.setAutoEnabled(true);
            goal.setAutoAmount(amount);
            goal.setAutoFrequency(frequency.name());
            goal.setAutoNextRun(frequency.next(LocalDateTime.now()));
            log.info("Auto-save on for goal {}: {} {} {}", goalId, amount, goal.getCurrencyCode(), frequency);
            return goalRepository.save(goal);
        }));
    }

    /**
     * Turns the automatic save off. The amount and period are kept so turning it back on is one tap.
     */
    public GoalDTO disableAutoSave(UUID userId, UUID goalId) {
        ownedGoal(userId, goalId);
        return toDto(tx.execute(status -> {
            SavingsGoalModel goal = lockedGoal(userId, goalId);
            goal.setAutoEnabled(false);
            goal.setAutoNextRun(null);
            log.info("Auto-save off for goal {}", goalId);
            return goalRepository.save(goal);
        }));
    }

    /**
     * Deletes the goal. Whatever is saved in it goes back to the wallet account FIRST, in the same
     * all-or-nothing step, so deleting a goal can never make money disappear.
     */
    public DeletedGoalDTO delete(UUID userId, UUID goalId) {
        UserModel user = activeUser(userId);
        SavingsGoalModel peek = ownedGoal(userId, goalId);
        BigDecimal saved = peek.getSavedAmount();

        if (saved.signum() <= 0) {
            return tx.execute(status -> {
                SavingsGoalModel goal = lockedGoal(userId, goalId);
                if (goal.getSavedAmount().signum() > 0) {
                    throw new IllegalArgumentException("Money was just added to this goal. Please try again.");
                }
                goalRepository.delete(goal);
                log.info("Savings goal {} deleted (it was empty)", goalId);
                return new DeletedGoalDTO(goalId, goal.getGoalName(), goal.getCurrencyCode(), BigDecimal.ZERO);
            });
        }

        TransactionModel attempt = draft(user, peek, Datatypes.TransactionType.SAVINGS_WITHDRAWAL, saved, false);
        attempt.setPurpose(truncate("Goal deleted, savings returned: " + peek.getGoalName()));
        try {
            return tx.execute(status -> {
                SavingsGoalModel goal = lockedGoal(userId, goalId);
                if (goal.getSavedAmount().compareTo(saved) != 0) {
                    throw new IllegalArgumentException("The goal changed while it was being deleted. Please try again.");
                }
                FiatAccountModel account = requireAccount(userId, goal.getCurrencyCode());
                TransactionModel txn = ledgerOperations.creditInternal(attempt, account,
                        "Goal deleted: " + goal.getGoalName(), "Goal deleted",
                        goal.getCurrencyCode() + " " + saved.toPlainString() + " from your goal \"" + goal.getGoalName() + "\" was returned to your wallet.");
                userSavingsRepository.save(UserSavingsModel.builder()
                        .userId(userId).currencyCode(goal.getCurrencyCode()).amount(saved.negate())
                        .source(Datatypes.SavingsSource.MILESTONE).referenceId(goal.getGoalId())
                        .note(truncate("Goal deleted: " + goal.getGoalName())).build());
                goalRepository.delete(goal);
                log.info("Savings goal {} deleted; {} {} returned to the wallet (txn {})", goalId, saved, goal.getCurrencyCode(), txn.getTransactionId());
                return new DeletedGoalDTO(goalId, goal.getGoalName(), goal.getCurrencyCode(), saved);
            });
        } catch (RuntimeException e) {
            transactionRecorder.recordFailure(attempt, reasonOf(e));
            throw e;
        }
    }

    // --------------------------------------------------------------- activity

    /**
     * The user's most recent goal deposits, withdrawals and automatic saves (refused ones included), newest first.
     */
    @Transactional(readOnly = true)
    public List<ActivityDTO> recentActivity(UUID userId, int limit) {
        int size = Math.min(Math.max(limit, 1), 100);
        return transactionRepository.findUserByTypes(userId,
                        List.of(Datatypes.TransactionType.SAVINGS_DEPOSIT, Datatypes.TransactionType.SAVINGS_WITHDRAWAL),
                        PageRequest.of(0, size)).stream()
                .map(SavingsGoalService::toActivity).toList();
    }

    // ------------------------------------------------------- scheduled auto-save

    /**
     * Runs every automatic save that is due. Called by {@link SavingsAutoSaveJob} once a minute.
     * Each goal is handled on its own, so one failing goal never stops the others.
     *
     * @return how many automatic saves went through
     */
    public int processDueAutoSaves() {
        List<UUID> due = goalRepository.findDueAutoSaveIds(LocalDateTime.now(), PageRequest.of(0, 200));
        int saved = 0;
        for (UUID goalId : due) {
            try {
                AutoRun run = claimAutoRun(goalId);
                if (run == null) {
                    continue;
                }
                deposit(run.userId(), goalId, run.amount(), true);
                saved++;
            } catch (RuntimeException e) {
                // deposit() already saved the refused attempt as a FAILED transaction the user can see
                log.warn("Auto-save for goal {} did not go through: {}", goalId, e.getMessage());
            }
        }
        return saved;
    }

    /**
     * Takes one due run: moves the goal's next run forward in its own committed step BEFORE any money moves, so
     * the same run can never be taken twice (two app instances, a slow save, a restart). A frozen goal keeps its
     * due run and goes off right after the freeze ends.
     */
    private AutoRun claimAutoRun(UUID goalId) {
        return tx.execute(status -> {
            SavingsGoalModel goal = goalRepository.findByIdForUpdate(goalId).orElse(null);
            LocalDateTime now = LocalDateTime.now();
            if (goal == null || !goal.isAutoEnabled() || goal.getAutoNextRun() == null || goal.getAutoNextRun().isAfter(now)) {
                return null;
            }
            if ("COMPLETED".equals(goal.getStatus()) || "CLOSED".equals(goal.getStatus())) {
                // Target reached: the automatic saving has done its job
                goal.setAutoEnabled(false);
                goal.setAutoNextRun(null);
                goalRepository.save(goal);
                return null;
            }
            if (isFrozen(goal, now)) {
                return null;
            }
            goal.setAutoNextRun(Frequency.parse(goal.getAutoFrequency()).next(now));
            goalRepository.save(goal);
            return new AutoRun(goal.getUserId(), goal.getAutoAmount());
        });
    }

    private record AutoRun(UUID userId, BigDecimal amount) {
    }

    // ---------------------------------------------------------------- helpers

    private static final int MAX_FREEZE_DAYS = 7;
    private static final DateTimeFormatter FROZEN_FORMAT = DateTimeFormatter.ofPattern("d MMM yyyy, HH:mm");

    /**
     * How often the automatic save runs.
     */
    enum Frequency {
        DAILY, WEEKLY, MONTHLY;

        static Frequency parse(String value) {
            try {
                return valueOf(value == null ? "" : value.trim().toUpperCase());
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("Choose how often to save: daily, weekly or monthly");
            }
        }

        LocalDateTime next(LocalDateTime from) {
            return switch (this) {
                case DAILY -> from.plusDays(1);
                case WEEKLY -> from.plusWeeks(1);
                case MONTHLY -> from.plusMonths(1);
            };
        }
    }

    private static boolean isFrozen(SavingsGoalModel goal, LocalDateTime now) {
        return goal.getFrozenUntil() != null && goal.getFrozenUntil().isAfter(now);
    }

    private SavingsGoalModel lockedGoal(UUID userId, UUID goalId) {
        return goalRepository.findOwnedForUpdate(goalId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Savings goal not found"));
    }

    private static Instant instant(LocalDateTime time) {
        return time == null ? null : time.atZone(ZoneId.systemDefault()).toInstant();
    }

    // A goal is COMPLETED while the saved amount has reached its target, ACTIVE otherwise
    private static void refreshStatus(SavingsGoalModel goal) {
        if ("CLOSED".equals(goal.getStatus())) {
            return;
        }
        boolean reached = goal.getTargetAmount() != null && goal.getSavedAmount().compareTo(goal.getTargetAmount()) >= 0;
        goal.setStatus(reached ? "COMPLETED" : "ACTIVE");
    }

    // The transaction row for one move, not yet saved. Deposit = money out (user is sender), withdrawal = money in (user is receiver)
    private TransactionModel draft(UserModel user, SavingsGoalModel goal, Datatypes.TransactionType type, BigDecimal amount, boolean auto) {
        boolean deposit = type == Datatypes.TransactionType.SAVINGS_DEPOSIT;
        TransactionModel t = new TransactionModel();
        // "SAV-AUTO-" marks a scheduled save so the activity list can tell it from a manual one
        t.setInternalReferenceId((auto ? AUTO_REF_PREFIX : "SAV-") + UUID.randomUUID());
        t.setTransactionType(type);
        t.setAmount(amount);
        t.setSourceCurrencyCode(goal.getCurrencyCode());
        t.setDestinationCurrencyCode(goal.getCurrencyCode());
        t.setDestinationAmount(amount);
        t.setPurpose(truncate((deposit ? (auto ? "Auto-saved to goal: " : "Saved to goal: ") : "Withdrawn from goal: ") + goal.getGoalName()));
        t.setDestinationIdentifier(goal.getGoalId().toString());
        String userName = user.getFirstName() + " " + user.getLastName();
        if (deposit) {
            t.setSenderId(user.getUserId());
            t.setSenderName(userName);
            t.setSenderEmail(user.getEmail());
            t.setSenderPhoneNumber(user.getPhoneNumber());
            t.setReceiverName("Goal: " + goal.getGoalName());
        } else {
            t.setReceiverId(user.getUserId());
            t.setReceiverName(userName);
            t.setReceiverEmail(user.getEmail());
            t.setReceiverPhoneNumber(user.getPhoneNumber());
            t.setSenderName("Goal: " + goal.getGoalName());
        }
        return t;
    }

    private SavingsGoalModel ownedGoal(UUID userId, UUID goalId) {
        // Same answer for "no such goal" and "someone else's goal"
        return goalRepository.findById(goalId).filter(g -> g.getUserId().equals(userId))
                .orElseThrow(() -> new ResourceNotFoundException("Savings goal not found"));
    }

    private FiatAccountModel requireAccount(UUID userId, String currency) {
        try {
            return ledgerOperations.walletAccount(userId, currency);
        } catch (ResourceNotFoundException e) {
            throw new IllegalArgumentException("You do not have a " + currency + " account yet. Please create one first.");
        }
    }

    private UserModel activeUser(UUID userId) {
        UserModel user = userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        if (user.getStatus() != Datatypes.UserStatus.ACTIVE) {
            throw new IllegalArgumentException("Your account is " + user.getStatus() + " at the moment");
        }
        return user;
    }

    private static BigDecimal positive(BigDecimal amount) {
        BigDecimal value = amount == null ? BigDecimal.ZERO : money(amount);
        if (value.signum() <= 0) {
            throw new IllegalArgumentException("Amount must be greater than zero");
        }
        return value;
    }

    private static BigDecimal money(BigDecimal amount) {
        return amount.setScale(2, RoundingMode.HALF_UP);
    }

    private static String reasonOf(RuntimeException e) {
        return e.getMessage() == null || e.getMessage().isBlank() ? "The savings move could not be completed" : e.getMessage();
    }

    private static String clean(String value) {
        return value == null || value.isBlank() ? null : truncate(value.trim());
    }

    private static String truncate(String text) {
        return text.length() > 250 ? text.substring(0, 250) : text;
    }

    private static GoalDTO toDto(SavingsGoalModel g) {
        // A freeze that has run out is simply "not frozen": nothing has to clear it
        Instant frozenUntil = isFrozen(g, LocalDateTime.now()) ? instant(g.getFrozenUntil()) : null;
        return new GoalDTO(g.getGoalId(), g.getGoalName(), g.getCurrencyCode(), g.getSavedAmount(),
                g.getTargetAmount(), g.getTargetDate(), g.getStatus(), g.getDescription(),
                frozenUntil, g.isAutoEnabled(), g.getAutoAmount(), g.getAutoFrequency(),
                g.isAutoEnabled() ? instant(g.getAutoNextRun()) : null, instant(g.getCreatedAt()));
    }

    private static ActivityDTO toActivity(TransactionModel t) {
        boolean deposit = t.getTransactionType() == Datatypes.TransactionType.SAVINGS_DEPOSIT;
        // The goal's name travels on the transaction as "Goal: <name>" (the other side of the move is the user)
        String label = deposit ? t.getReceiverName() : t.getSenderName();
        String name = label == null ? "Savings goal" : label.startsWith("Goal: ") ? label.substring(6) : label;
        UUID goalId = null;
        try {
            goalId = t.getDestinationIdentifier() == null ? null : UUID.fromString(t.getDestinationIdentifier());
        } catch (IllegalArgumentException ignored) {
            // not a goal id: the row is still shown, just without a link to a goal
        }
        boolean auto = deposit && t.getInternalReferenceId() != null && t.getInternalReferenceId().startsWith(AUTO_REF_PREFIX);
        return new ActivityDTO(t.getTransactionId(), goalId, name, deposit ? "DEPOSIT" : "WITHDRAWAL", auto,
                t.getAmount(), t.getSourceCurrencyCode(), t.getStatus() == null ? null : t.getStatus().name(),
                t.getFailureReason(), instant(t.getCreatedAt()));
    }
}
