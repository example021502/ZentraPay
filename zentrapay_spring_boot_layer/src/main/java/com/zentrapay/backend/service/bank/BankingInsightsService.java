package com.zentrapay.backend.service.bank;

import com.zentrapay.backend.dto.bank.BankingInsightDTOs.BudgetDTO;
import com.zentrapay.backend.dto.bank.BankingInsightDTOs.InsightsDTO;
import com.zentrapay.backend.dto.bank.BankingInsightDTOs.SpendCategoryDTO;
import com.zentrapay.backend.entity.TransactionModel;
import com.zentrapay.backend.entity.UserBudgetModel;
import com.zentrapay.backend.repository.TransactionRepository;
import com.zentrapay.backend.repository.UserBudgetRepository;
import com.zentrapay.backend.repository.UserRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.Datatypes.TransactionStatus;
import com.zentrapay.backend.service.common.Datatypes.TransactionType;
import com.zentrapay.backend.service.CountriesServices;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.TemporalAdjusters;
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
    private final UserBudgetRepository budgetRepository;
    private final CountriesServices countriesServices;

    @Transactional(readOnly = true)
    public InsightsDTO insights(UUID userId, Datatypes.BudgetPeriod period) {

        List<TransactionModel> transactions = transactions(userId, period);

        BigDecimal spend = BigDecimal.ZERO;
        BigDecimal income = BigDecimal.ZERO;
        Map<String, BigDecimal> byCategory = new HashMap<>();
        for (TransactionModel t : transactions) {
            String category = SPEND_CATEGORY.get(t.getTransactionType());
            if (category != null && userId.equals(t.getSenderId())) {
                spend = spend.add(t.getAmount());
                byCategory.merge(category, t.getAmount(), BigDecimal::add);
            }
            if (t.getTransactionType() == TransactionType.P2P_TRANSFER && userId.equals(t.getReceiverId())
                    && !userId.equals(t.getSenderId())) {
                income = income.add(t.getDestinationAmount() == null ? t.getAmount() : t.getDestinationAmount());
            }
        }
        List<SpendCategoryDTO> top = byCategory.entrySet().stream()
                .sorted(Map.Entry.<String, BigDecimal>comparingByValue().reversed())
                .limit(5)
                .map(e -> new SpendCategoryDTO(e.getKey(), money(e.getValue())))
                .toList();
        return new InsightsDTO(money(spend), money(income), period, top);
    }

    @Transactional(readOnly = true)
    public BudgetDTO budget(UUID userId, String currencyCode, Datatypes.BudgetPeriod period) {
        BigDecimal limit = budgetRepository.findByUserIdAndCurrencyCode(userId, currencyCode).map(UserBudgetModel::getLimit).orElse(BigDecimal.ZERO);
        return summary(userId, currencyCode, limit, period);
    }

    /**
     * Sets (or changes) the monthly limit; 0 clears it.
     */
    @Transactional
    public BudgetDTO setBudget(UUID userId, BigDecimal limit, String currencyCode, Datatypes.BudgetPeriod period) {
        UserBudgetModel row = budgetRepository.findById(userId).orElseGet(() -> {
            UserBudgetModel fresh = new UserBudgetModel();
            fresh.setUserId(userId);
            return fresh;
        });
        row.setLimit(money(limit));
        row.setCurrencyCode(currencyCode);
        row.setPeriod(period);
        budgetRepository.save(row);
        return summary(userId, currencyCode, money(limit), period);
    }

    // ---------------------------------------------------------------- helpers

    private BudgetDTO summary(UUID userId, String currency, BigDecimal limit, Datatypes.BudgetPeriod period) {
        BigDecimal spent = insights(userId, period).spend();
        BigDecimal remaining = limit.subtract(spent).max(BigDecimal.ZERO);
        return new BudgetDTO(currency, limit, spent, money(remaining), period);
    }

    private List<TransactionModel> transactions(UUID userId, Datatypes.BudgetPeriod period) {
        LocalDateTime from = getPeriod(period);
        return transactionRepository.findUserSince(userId, from, COUNTED);
    }

    private LocalDateTime getPeriod(Datatypes.BudgetPeriod period) {
        LocalDate today = LocalDate.now();
        return switch (period) {
            case DAILY -> today.atStartOfDay();
            case WEEKLY -> today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY)).atStartOfDay();
            case MONTHLY -> today.withDayOfMonth(1).atStartOfDay();
            case YEARLY -> today.withDayOfYear(1).atStartOfDay();
        };
    }

    private static BigDecimal money(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }
}
