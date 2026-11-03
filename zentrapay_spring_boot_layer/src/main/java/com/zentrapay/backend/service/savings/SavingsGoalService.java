package com.zentrapay.backend.service.savings;

import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.CreateGoalRequest;
import com.zentrapay.backend.dto.savings.SavingsGoalDTOs.GoalDTO;
import com.zentrapay.backend.entity.FiatAccountModel;
import com.zentrapay.backend.entity.SavingsGoalModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.entity.UserSavingsModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.SavingsGoalRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.repository.UserSavingsRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.payment.LedgerOperations;
import com.zentrapay.backend.service.payment.TransactionRecorder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
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

    private final SavingsGoalRepository goalRepository;
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

    /** Creates a goal and, when {@code initialDeposit} is given, funds it from the wallet right away. */
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

    /** Moves {@code amount} from the user's wallet account into the goal. */
    public GoalDTO deposit(UUID userId, UUID goalId, BigDecimal rawAmount) {
        UserModel user = activeUser(userId);
        BigDecimal amount = positive(rawAmount);
        SavingsGoalModel peek = ownedGoal(userId, goalId);
        TransactionModel attempt = draft(user, peek, Datatypes.TransactionType.SAVINGS_DEPOSIT, amount);
        try {
            SavingsGoalModel result = tx.execute(status -> {
                SavingsGoalModel goal = goalRepository.findOwnedForUpdate(goalId, userId)
                        .orElseThrow(() -> new ResourceNotFoundException("Savings goal not found"));
                if ("CLOSED".equals(goal.getStatus())) {
                    throw new IllegalArgumentException("This goal is closed");
                }
                FiatAccountModel account = requireAccount(userId, goal.getCurrencyCode());
                if (!"ACTIVE".equalsIgnoreCase(account.getStatus())) {
                    throw new IllegalArgumentException("Your " + goal.getCurrencyCode() + " account is " + account.getStatus() + " at the moment");
                }
                if (account.getBalance().compareTo(amount) < 0) {
                    throw new IllegalArgumentException("Insufficient balance. Please top up your " + goal.getCurrencyCode() + " account first");
                }
                TransactionModel txn = ledgerOperations.debitInternal(attempt, account,
                        "Saved to goal: " + goal.getGoalName(), "Money saved",
                        goal.getCurrencyCode() + " " + amount.toPlainString() + " was added to your goal \"" + goal.getGoalName() + "\".");

                goal.setSavedAmount(goal.getSavedAmount().add(amount));
                refreshStatus(goal);
                goalRepository.save(goal);
                userSavingsRepository.save(UserSavingsModel.builder()
                        .userId(userId).currencyCode(goal.getCurrencyCode()).amount(amount)
                        .source(Datatypes.SavingsSource.MILESTONE).referenceId(goal.getGoalId())
                        .note(truncate("Goal: " + goal.getGoalName())).build());
                log.info("Savings: {} {} into goal {} (txn {})", amount, goal.getCurrencyCode(), goal.getGoalId(), txn.getTransactionId());
                return goal;
            });
            return toDto(result);
        } catch (RuntimeException e) {
            transactionRecorder.recordFailure(attempt, reasonOf(e));
            throw e;
        }
    }

    /** Moves {@code amount} from the goal back to the user's wallet account. */
    public GoalDTO withdraw(UUID userId, UUID goalId, BigDecimal rawAmount) {
        UserModel user = activeUser(userId);
        BigDecimal amount = positive(rawAmount);
        SavingsGoalModel peek = ownedGoal(userId, goalId);
        TransactionModel attempt = draft(user, peek, Datatypes.TransactionType.SAVINGS_WITHDRAWAL, amount);
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

    // ---------------------------------------------------------------- helpers

    // A goal is COMPLETED while the saved amount has reached its target, ACTIVE otherwise
    private static void refreshStatus(SavingsGoalModel goal) {
        if ("CLOSED".equals(goal.getStatus())) {
            return;
        }
        boolean reached = goal.getTargetAmount() != null && goal.getSavedAmount().compareTo(goal.getTargetAmount()) >= 0;
        goal.setStatus(reached ? "COMPLETED" : "ACTIVE");
    }

    // The transaction row for one move, not yet saved. Deposit = money out (user is sender), withdrawal = money in (user is receiver)
    private TransactionModel draft(UserModel user, SavingsGoalModel goal, Datatypes.TransactionType type, BigDecimal amount) {
        boolean deposit = type == Datatypes.TransactionType.SAVINGS_DEPOSIT;
        TransactionModel t = new TransactionModel();
        t.setInternalReferenceId("SAV-" + UUID.randomUUID());
        t.setTransactionType(type);
        t.setAmount(amount);
        t.setSourceCurrencyCode(goal.getCurrencyCode());
        t.setDestinationCurrencyCode(goal.getCurrencyCode());
        t.setDestinationAmount(amount);
        t.setPurpose(truncate((deposit ? "Saved to goal: " : "Withdrawn from goal: ") + goal.getGoalName()));
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
        return new GoalDTO(g.getGoalId(), g.getGoalName(), g.getCurrencyCode(), g.getSavedAmount(),
                g.getTargetAmount(), g.getTargetDate(), g.getStatus(), g.getDescription());
    }
}
