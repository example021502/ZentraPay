package com.zentrapay.backend.service.invest;

import com.zentrapay.backend.dto.invest.InvestmentDTOs.InvestRequest;
import com.zentrapay.backend.dto.invest.InvestmentDTOs.InvestmentDTO;
import com.zentrapay.backend.entity.FiatAccountModel;
import com.zentrapay.backend.entity.InvestmentModel;
import com.zentrapay.backend.entity.InvestmentPriceSnapshotModel;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.InvestmentPriceSnapshotRepository;
import com.zentrapay.backend.repository.InvestmentRepository;
import com.zentrapay.backend.repository.UserRepository;
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
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * ZInvest: the user opens a position (a stock, a commodity ...) and later sells it.
 *
 * <p>Money really moves: buying takes {@code quantity x buy price} out of the wallet account in the
 * position's currency, selling puts {@code quantity x current price} back. Each move is one
 * all-or-nothing database step (wallet debit/credit, the {@code transactions} row INVESTMENT_BUY /
 * INVESTMENT_SELL and its ledger entry), the same way savings goals work. A refused attempt is still
 * saved as a FAILED transaction so the history shows it.
 *
 * <p><b>There is no market-data feed yet.</b> The current price of a position is the newest row in
 * {@code investment_price_snapshots}; the only row written today is the one at the buy price, so a
 * position sells for what it cost until something records newer prices.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class InvestmentService {

    private static final Set<String> TYPES = Set.of("STOCK", "ETF", "COMMODITY", "CRYPTO", "OTHER");
    private static final BigDecimal MAX_COST = new BigDecimal("1000000000");

    private final InvestmentRepository investmentRepository;
    private final InvestmentPriceSnapshotRepository snapshotRepository;
    private final UserRepository userRepository;
    private final LedgerOperations ledgerOperations;
    private final TransactionRecorder transactionRecorder;
    private final TransactionTemplate tx;

    // ------------------------------------------------------------------ reads

    /** The user's positions, newest first, each with its current price. */
    @Transactional(readOnly = true)
    public List<InvestmentDTO> portfolio(UUID userId) {
        return investmentRepository.findByUserIdOrderByCreatedAtDesc(userId).stream().map(this::toDto).toList();
    }

    // ----------------------------------------------------------------- writes

    /** Opens a position and takes its cost from the wallet account in the same currency. */
    public InvestmentDTO invest(UUID userId, InvestRequest req) {
        UserModel user = activeUser(userId);
        String type = req.investmentType().trim().toUpperCase();
        if (!TYPES.contains(type)) {
            throw new IllegalArgumentException("Unknown investment type");
        }
        if ("CRYPTO".equals(type)) {
            throw new IllegalArgumentException("Crypto investing is not available yet");
        }
        String name = req.name().trim();
        if (name.isEmpty() || name.length() > 120) {
            throw new IllegalArgumentException("Give the investment a name (up to 120 characters)");
        }
        String symbol = req.symbol() == null || req.symbol().isBlank() ? null : req.symbol().trim().toUpperCase();
        if (symbol != null && symbol.length() > 20) {
            throw new IllegalArgumentException("The symbol is too long (up to 20 characters)");
        }
        BigDecimal quantity = req.quantity().setScale(4, RoundingMode.HALF_UP);
        BigDecimal price = req.buyPrice().setScale(4, RoundingMode.HALF_UP);
        if (quantity.signum() <= 0 || price.signum() <= 0) {
            throw new IllegalArgumentException("Quantity and buy price must be greater than zero");
        }
        BigDecimal cost = quantity.multiply(price).setScale(2, RoundingMode.HALF_UP);
        if (cost.compareTo(new BigDecimal("0.01")) < 0 || cost.compareTo(MAX_COST) > 0) {
            throw new IllegalArgumentException("That amount is outside the allowed range");
        }
        String currency = req.currencyCode().trim().toUpperCase();

        TransactionModel attempt = draft(user, Datatypes.TransactionType.INVESTMENT_BUY, cost, currency,
                "Invested in " + name, null);
        try {
            InvestmentModel result = tx.execute(status -> {
                FiatAccountModel account = requireAccount(userId, currency);
                if (!"ACTIVE".equalsIgnoreCase(account.getStatus())) {
                    throw new IllegalArgumentException("Your " + currency + " account is " + account.getStatus() + " at the moment");
                }
                if (account.getBalance().compareTo(cost) < 0) {
                    throw new IllegalArgumentException("Insufficient balance. Please top up your " + currency + " account first");
                }
                TransactionModel txn = ledgerOperations.debitInternal(attempt, account,
                        "Invested in " + name, "Investment bought",
                        currency + " " + cost.toPlainString() + " was invested in " + name + ".");

                InvestmentModel position = new InvestmentModel();
                position.setUserId(userId);
                position.setName(name);
                position.setInvestmentType(type);
                position.setSymbol(symbol);
                position.setQuantity(quantity);
                position.setBuyPrice(price);
                position.setCurrencyCode(currency);
                position = investmentRepository.save(position);

                InvestmentPriceSnapshotModel snapshot = new InvestmentPriceSnapshotModel();
                snapshot.setInvestmentId(position.getInvestmentId());
                snapshot.setPrice(price);
                snapshotRepository.save(snapshot);
                log.info("ZInvest: user {} bought {} x {} {} (txn {})", userId, quantity, name, currency, txn.getTransactionId());
                return position;
            });
            return toDto(result);
        } catch (RuntimeException e) {
            transactionRecorder.recordFailure(attempt, reasonOf(e));
            throw e;
        }
    }

    /** Sells a position: its value at the current price goes back into the wallet, the position is closed. */
    public InvestmentDTO sell(UUID userId, UUID investmentId) {
        UserModel user = activeUser(userId);
        InvestmentModel peek = investmentRepository.findById(investmentId).filter(i -> i.getUserId().equals(userId))
                // Same answer for "no such position" and "someone else's position"
                .orElseThrow(() -> new ResourceNotFoundException("Investment not found"));
        BigDecimal proceeds = valueOf(peek);
        TransactionModel attempt = draft(user, Datatypes.TransactionType.INVESTMENT_SELL, proceeds, peek.getCurrencyCode(),
                "Sold " + peek.getName(), peek.getInvestmentId());
        try {
            InvestmentModel result = tx.execute(status -> {
                InvestmentModel position = investmentRepository.findOwnedForUpdate(investmentId, userId)
                        .orElseThrow(() -> new ResourceNotFoundException("Investment not found"));
                if (!"ACTIVE".equals(position.getStatus())) {
                    throw new IllegalArgumentException("This investment has already been sold");
                }
                // Re-priced inside the lock: the amount paid out is the value of the position as it is right now
                BigDecimal amount = valueOf(position);
                attempt.setAmount(amount);
                attempt.setDestinationAmount(amount);
                FiatAccountModel account = requireAccount(userId, position.getCurrencyCode());
                TransactionModel txn = ledgerOperations.creditInternal(attempt, account,
                        "Sold " + position.getName(), "Investment sold",
                        position.getCurrencyCode() + " " + amount.toPlainString() + " from selling " + position.getName() + " is in your wallet.");
                position.setStatus("CLOSED");
                investmentRepository.save(position);
                log.info("ZInvest: user {} sold {} for {} {} (txn {})", userId, position.getName(), amount, position.getCurrencyCode(), txn.getTransactionId());
                return position;
            });
            return toDto(result);
        } catch (RuntimeException e) {
            transactionRecorder.recordFailure(attempt, reasonOf(e));
            throw e;
        }
    }

    // ---------------------------------------------------------------- helpers

    // Current price: the newest snapshot, or the buy price when nothing was recorded
    private BigDecimal currentPrice(InvestmentModel i) {
        return snapshotRepository.findFirstByInvestmentIdOrderByRecordedAtDesc(i.getInvestmentId())
                .map(InvestmentPriceSnapshotModel::getPrice).orElse(i.getBuyPrice());
    }

    private BigDecimal valueOf(InvestmentModel i) {
        return i.getQuantity().multiply(currentPrice(i)).setScale(2, RoundingMode.HALF_UP);
    }

    // The transaction row for one move, not yet saved. Buy = money out (user is sender), sell = money in (user is receiver)
    private TransactionModel draft(UserModel user, Datatypes.TransactionType type, BigDecimal amount, String currency,
                                   String purpose, UUID investmentId) {
        boolean buy = type == Datatypes.TransactionType.INVESTMENT_BUY;
        TransactionModel t = new TransactionModel();
        t.setInternalReferenceId("INV-" + UUID.randomUUID());
        t.setTransactionType(type);
        t.setAmount(amount);
        t.setSourceCurrencyCode(currency);
        t.setDestinationCurrencyCode(currency);
        t.setDestinationAmount(amount);
        t.setPurpose(purpose.length() > 250 ? purpose.substring(0, 250) : purpose);
        t.setDestinationIdentifier(investmentId == null ? null : investmentId.toString());
        String userName = user.getFirstName() + " " + user.getLastName();
        if (buy) {
            t.setSenderId(user.getUserId());
            t.setSenderName(userName);
            t.setSenderEmail(user.getEmail());
            t.setSenderPhoneNumber(user.getPhoneNumber());
            t.setReceiverName("ZInvest");
        } else {
            t.setReceiverId(user.getUserId());
            t.setReceiverName(userName);
            t.setReceiverEmail(user.getEmail());
            t.setReceiverPhoneNumber(user.getPhoneNumber());
            t.setSenderName("ZInvest");
        }
        return t;
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

    private static String reasonOf(RuntimeException e) {
        return e.getMessage() == null || e.getMessage().isBlank() ? "The investment could not be completed" : e.getMessage();
    }

    private InvestmentDTO toDto(InvestmentModel i) {
        return new InvestmentDTO(i.getInvestmentId(), i.getName(), i.getInvestmentType(), i.getSymbol(), i.getQuantity(),
                i.getBuyPrice(), currentPrice(i), i.getCurrencyCode(), i.getStatus());
    }
}
