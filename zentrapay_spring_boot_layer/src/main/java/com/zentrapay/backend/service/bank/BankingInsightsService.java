package com.zentrapay.backend.service.bank;

import com.zentrapay.backend.dto.bank.BankingInsightDTOs.BudgetDTO;
import com.zentrapay.backend.dto.bank.BankingInsightDTOs.InsightsDTO;
import com.zentrapay.backend.dto.bank.BankingInsightDTOs.SpendCategoryDTO;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserBudgetModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.TransactionRepository;
import com.zentrapay.backend.repository.UserBudgetRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.service.common.Datatypes.TransactionStatus;
import com.zentrapay.backend.service.common.Datatypes.TransactionType;
import com.zentrapay.backend.service.region.SupportedRegionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.*;

/**
 * ZBank "insights" and the monthly budget, worked out from the user's own transactions.
 *
 * <ul>
 *   <li><b>Spend</b> = money the user SENT this calendar month on transfers, bank / mobile-money
 *       payouts, bills and loan repayments (fees included). Moving money into a savings goal or an
 *       investment is not spending, so it is left out.</li>
 *   <li><b>Income</b> = money the user RECEIVED from other ZentraPay users this month. Top-ups from
 *       the user's own bank or card are not income.</li>
 *   <li>Only the user's home currency (the default currency of their country) is added up, so
 *       different currencies are never summed together.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class BankingInsightsService {

    // Open and finished-successfully payments count; failed / refunded ones never took the money
    private static final Set<TransactionStatus> COUNTED =
            EnumSet.of(TransactionStatus.SUCCESS, TransactionStatus.PENDING, TransactionStatus.INITIATED);

    // Outgoing types that are spending, with the category each one is shown under
    private static final Map<TransactionType, String> SPEND_CATEGORY = Map.of(
            TransactionType.P2P_TRANSFER, "TRANSFERS",
            TransactionType.CASH_OUT_BANK, "BANK_TRANSFERS",
            TransactionType.CASH_OUT_MOMO, "MOBILE_MONEY",
            TransactionType.BILL_PAYMENT, "BILLS",
            TransactionType.LOAN_REPAYMENT, "LOANS",
            TransactionType.PLATFORM_FEE, "FEES");

    private final TransactionRepository transactionRepository;
    private final UserRepository userRepository;
    private final UserBudgetRepository budgetRepository;
    private final SupportedRegionService supportedRegionService;

    @Transactional(readOnly = true)
    public InsightsDTO insights(UUID userId) {
        String currency = homeCurrency(userId);
        List<TransactionModel> month = thisMonth(userId);

        BigDecimal spend = BigDecimal.ZERO;
        BigDecimal income = BigDecimal.ZERO;
        Map<String, BigDecimal> byCategory = new HashMap<>();
        for (TransactionModel t : month) {
            String category = SPEND_CATEGORY.get(t.getTransactionType());
            if (category != null && userId.equals(t.getSenderId()) && currency.equalsIgnoreCase(t.getSourceCurrencyCode())) {
                spend = spend.add(t.getAmount());
                byCategory.merge(category, t.getAmount(), BigDecimal::add);
            }
            if (t.getTransactionType() == TransactionType.P2P_TRANSFER && userId.equals(t.getReceiverId())
                    && !userId.equals(t.getSenderId()) && currency.equalsIgnoreCase(t.getDestinationCurrencyCode())) {
                income = income.add(t.getDestinationAmount() == null ? t.getAmount() : t.getDestinationAmount());
            }
        }
        List<SpendCategoryDTO> top = byCategory.entrySet().stream()
                .sorted(Map.Entry.<String, BigDecimal>comparingByValue().reversed())
                .limit(5)
                .map(e -> new SpendCategoryDTO(e.getKey(), money(e.getValue())))
                .toList();
        return new InsightsDTO(currency, money(spend), money(income), top);
    }

    @Transactional(readOnly = true)
    public BudgetDTO budget(UUID userId) {
        String currency = homeCurrency(userId);
        BigDecimal limit = budgetRepository.findById(userId).map(UserBudgetModel::getMonthlyLimit).orElse(BigDecimal.ZERO);
        return summary(userId, currency, limit);
    }

    /** Sets (or changes) the monthly limit; 0 clears it. */
    @Transactional
    public BudgetDTO setBudget(UUID userId, BigDecimal monthlyLimit) {
        String currency = homeCurrency(userId);
        BigDecimal limit = money(monthlyLimit);
        UserBudgetModel row = budgetRepository.findById(userId).orElseGet(() -> {
            UserBudgetModel fresh = new UserBudgetModel();
            fresh.setUserId(userId);
            return fresh;
        });
        row.setMonthlyLimit(limit);
        row.setCurrencyCode(currency);
        budgetRepository.save(row);
        return summary(userId, currency, limit);
    }

    // ---------------------------------------------------------------- helpers

    private BudgetDTO summary(UUID userId, String currency, BigDecimal limit) {
        BigDecimal spent = insights(userId).monthlySpend();
        BigDecimal remaining = limit.subtract(spent).max(BigDecimal.ZERO);
        return new BudgetDTO(currency, limit, spent, money(remaining));
    }

    private List<TransactionModel> thisMonth(UUID userId) {
        LocalDateTime from = LocalDate.now().withDayOfMonth(1).atStartOfDay();
        return transactionRepository.findUserSince(userId, from, COUNTED);
    }

    private String homeCurrency(UUID userId) {
        UserModel user = userRepository.findById(userId).orElseThrow(() -> new ResourceNotFoundException("User not found"));
        return supportedRegionService.defaultCurrencyOf(user.getCountryCode()).toUpperCase();
    }

    private static BigDecimal money(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }
}
