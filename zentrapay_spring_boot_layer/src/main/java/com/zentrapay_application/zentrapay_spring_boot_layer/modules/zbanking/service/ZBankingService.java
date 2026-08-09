package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Transaction;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionType;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Wallet;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.TransactionTypeRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.WalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model.Loan;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model.LoanRepayment;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model.SavingsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model.UserBudget;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.repository.LoanRepaymentRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.repository.LoanRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.repository.SavingsRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.repository.UserBudgetRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * Service for ZBanking: digital savings, micro-loans, budgeting, and insights —
 * API_CONTRACT.md §13.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class ZBankingService {

    private static final Logger log = LoggerFactory.getLogger(ZBankingService.class);

    // Simple, illustrative loan eligibility/pricing rule — not a real underwriting
    // engine. A requested amount is auto-approved if it's at most 3x the user's total
    // wallet balance across all currencies (currency mixing here is a simplification;
    // see final report).
    private static final BigDecimal ELIGIBILITY_MULTIPLE = new BigDecimal("3");
    private static final BigDecimal FLAT_INTEREST_RATE = new BigDecimal("15.0000");

    private final SavingsRepository savingsRepository;
    private final LoanRepository loanRepository;
    private final LoanRepaymentRepository loanRepaymentRepository;
    private final UserBudgetRepository userBudgetRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;
    private final TransactionTypeRepository transactionTypeRepository;

    // ========================================================================
    // SAVINGS
    // ========================================================================

    @Transactional(readOnly = true)
    public List<SavingsResponseDTO> getUserSavings(UUID userId) {
        return savingsRepository.findByUserId(userId).stream().map(this::toSavingsDTO).toList();
    }

    public SavingsResponseDTO createSavingsAccount(UUID userId, SavingsRequestDTO request) {
        Wallet wallet = walletRepository.findByUserIdAndCurrencyCode(userId, request.currencyCode())
                .orElseThrow(() -> new ResourceNotFoundException("No wallet found for currency " + request.currencyCode()));

        BigDecimal initialDeposit = request.initialDeposit() != null ? request.initialDeposit() : BigDecimal.ZERO;
        if (initialDeposit.compareTo(BigDecimal.ZERO) > 0) {
            if (wallet.getBalance().compareTo(initialDeposit) < 0) {
                throw new IllegalStateException("Insufficient balance for initial deposit");
            }
            int debited = walletRepository.debit(wallet.getWalletId(), initialDeposit);
            if (debited == 0) {
                throw new IllegalStateException("Insufficient balance for initial deposit");
            }
            recordTransaction(userId, wallet.getWalletId(), "SAVINGS_DEPOSIT", initialDeposit, request.currencyCode(),
                    "Savings deposit: " + request.savingsName());
        }

        SavingsModel savings = new SavingsModel();
        savings.setUserId(userId);
        savings.setWalletId(wallet.getWalletId());
        savings.setSavingsName(request.savingsName());
        savings.setCurrencyCode(request.currencyCode());
        savings.setBalance(initialDeposit);
        savings.setDescription(request.description());
        savings.setTargetDate(request.targetDate());
        savings.setTargetAmount(request.targetAmount());
        savings.setStatus("ACTIVE");

        return toSavingsDTO(savingsRepository.save(savings));
    }

    public SavingsResponseDTO depositToSavings(UUID userId, UUID savingsId, BigDecimal amount) {
        SavingsModel savings = getOwnedSavingsOrThrow(userId, savingsId);
        Wallet wallet = resolveWallet(userId, savings);

        if (wallet.getBalance().compareTo(amount) < 0) {
            throw new IllegalStateException("Insufficient wallet balance");
        }
        int debited = walletRepository.debit(wallet.getWalletId(), amount);
        if (debited == 0) {
            throw new IllegalStateException("Insufficient wallet balance");
        }
        recordTransaction(userId, wallet.getWalletId(), "SAVINGS_DEPOSIT", amount, savings.getCurrencyCode(),
                "Savings deposit: " + savings.getSavingsName());

        savings.setBalance(savings.getBalance().add(amount));
        return toSavingsDTO(savingsRepository.save(savings));
    }

    public SavingsResponseDTO withdrawFromSavings(UUID userId, UUID savingsId, BigDecimal amount) {
        SavingsModel savings = getOwnedSavingsOrThrow(userId, savingsId);
        if (savings.getBalance().compareTo(amount) < 0) {
            throw new IllegalStateException("Insufficient balance in savings account");
        }
        Wallet wallet = resolveWallet(userId, savings);

        walletRepository.credit(wallet.getWalletId(), amount);
        recordTransaction(userId, wallet.getWalletId(), "SAVINGS_WITHDRAWAL", amount, savings.getCurrencyCode(),
                "Savings withdrawal: " + savings.getSavingsName());

        savings.setBalance(savings.getBalance().subtract(amount));
        return toSavingsDTO(savingsRepository.save(savings));
    }

    private Wallet resolveWallet(UUID userId, SavingsModel savings) {
        if (savings.getWalletId() != null) {
            return walletRepository.findById(savings.getWalletId())
                    .orElseThrow(() -> new ResourceNotFoundException("Linked wallet not found"));
        }
        return walletRepository.findByUserIdAndCurrencyCode(userId, savings.getCurrencyCode())
                .orElseThrow(() -> new ResourceNotFoundException("No wallet found for currency " + savings.getCurrencyCode()));
    }

    private SavingsModel getOwnedSavingsOrThrow(UUID userId, UUID savingsId) {
        SavingsModel savings = savingsRepository.findById(savingsId)
                .orElseThrow(() -> new ResourceNotFoundException("Savings account not found"));
        if (!savings.getUserId().equals(userId)) {
            throw new ResourceNotFoundException("Savings account not found");
        }
        return savings;
    }

    private SavingsResponseDTO toSavingsDTO(SavingsModel s) {
        return new SavingsResponseDTO(s.getSavingsId(), s.getSavingsName(), s.getCurrencyCode(), s.getBalance(),
                s.getTargetAmount(), s.getTargetDate(), s.getStatus());
    }

    // ========================================================================
    // LOANS
    // ========================================================================

    @Transactional(readOnly = true)
    public List<LoanResponseDTO> getUserLoans(UUID userId) {
        return loanRepository.findByUserId(userId).stream().map(this::toLoanDTO).toList();
    }

    public LoanResponseDTO applyForLoan(UUID userId, LoanRequestDTO request) {
        BigDecimal totalBalance = walletRepository.findByUserId(userId).stream()
                .map(Wallet::getBalance)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        boolean eligible = request.amount().compareTo(totalBalance.multiply(ELIGIBILITY_MULTIPLE)) <= 0;

        Loan loan = new Loan();
        loan.setUserId(userId);
        loan.setCurrencyCode(request.currencyCode());
        loan.setPrincipalAmount(request.amount());
        loan.setInterestRate(FLAT_INTEREST_RATE);
        loan.setTermMonths(request.termMonths().shortValue());
        loan.setOutstandingBalance(request.amount());
        loan.setDueDate(LocalDate.now().plusMonths(request.termMonths()));

        if (eligible) {
            Wallet wallet = walletRepository.findByUserIdAndCurrencyCode(userId, request.currencyCode())
                    .orElseThrow(() -> new ResourceNotFoundException("No wallet found for currency " + request.currencyCode()));

            loan.setStatus("ACTIVE");
            loan.setApprovedAt(LocalDateTime.now());
            loan = loanRepository.save(loan);

            walletRepository.credit(wallet.getWalletId(), request.amount());
            Transaction transaction = recordTransaction(userId, wallet.getWalletId(), "LOAN_DISBURSEMENT",
                    request.amount(), request.currencyCode(), "Loan disbursement");
            loan.setDisbursementTransactionId(transaction.getTransactionId());
            loan = loanRepository.save(loan);
            log.info("[ZBANKING] Loan {} auto-approved and disbursed for userId={}", loan.getLoanId(), userId);
        } else {
            loan.setStatus("PENDING");
            loan = loanRepository.save(loan);
            log.info("[ZBANKING] Loan {} left PENDING for manual review (userId={})", loan.getLoanId(), userId);
        }

        return toLoanDTO(loan);
    }

    public LoanResponseDTO repayLoan(UUID userId, UUID loanId, BigDecimal amount) {
        Loan loan = loanRepository.findById(loanId)
                .orElseThrow(() -> new ResourceNotFoundException("Loan not found"));
        if (!loan.getUserId().equals(userId)) {
            throw new ResourceNotFoundException("Loan not found");
        }
        if (!"ACTIVE".equals(loan.getStatus())) {
            throw new IllegalStateException("Loan is not active");
        }
        if (amount.compareTo(loan.getOutstandingBalance()) > 0) {
            throw new IllegalArgumentException("Repayment amount exceeds outstanding balance");
        }

        Wallet wallet = walletRepository.findByUserIdAndCurrencyCode(userId, loan.getCurrencyCode())
                .orElseThrow(() -> new ResourceNotFoundException("No wallet found for currency " + loan.getCurrencyCode()));
        if (wallet.getBalance().compareTo(amount) < 0) {
            throw new IllegalStateException("Insufficient wallet balance");
        }
        int debited = walletRepository.debit(wallet.getWalletId(), amount);
        if (debited == 0) {
            throw new IllegalStateException("Insufficient wallet balance");
        }

        Transaction transaction = recordTransaction(userId, wallet.getWalletId(), "LOAN_REPAYMENT", amount,
                loan.getCurrencyCode(), "Loan repayment");

        LoanRepayment repayment = new LoanRepayment();
        repayment.setLoanId(loanId);
        repayment.setTransactionId(transaction.getTransactionId());
        repayment.setAmount(amount);
        loanRepaymentRepository.save(repayment);

        loan.setOutstandingBalance(loan.getOutstandingBalance().subtract(amount));
        if (loan.getOutstandingBalance().compareTo(BigDecimal.ZERO) <= 0) {
            loan.setStatus("CLOSED");
        }
        return toLoanDTO(loanRepository.save(loan));
    }

    private LoanResponseDTO toLoanDTO(Loan l) {
        return new LoanResponseDTO(l.getLoanId(), l.getPrincipalAmount(), l.getInterestRate(), l.getTermMonths(),
                l.getOutstandingBalance(), l.getStatus(), l.getDueDate());
    }

    // ========================================================================
    // BUDGET
    // ========================================================================

    @Transactional(readOnly = true)
    public BudgetDTO getBudget(UUID userId) {
        BigDecimal monthlyLimit = userBudgetRepository.findById(userId)
                .map(UserBudget::getMonthlyLimit)
                .orElse(BigDecimal.ZERO);
        BigDecimal spent = monthlySpend(userId);
        return new BudgetDTO(monthlyLimit, spent, monthlyLimit.subtract(spent));
    }

    public BudgetDTO updateBudget(UUID userId, BudgetUpdateRequestDTO request) {
        UserBudget budget = userBudgetRepository.findById(userId).orElseGet(() -> {
            UserBudget b = new UserBudget();
            b.setUserId(userId);
            b.setCurrencyCode(defaultCurrencyFor(userId));
            return b;
        });
        budget.setMonthlyLimit(request.monthlyLimit());
        userBudgetRepository.save(budget);

        BigDecimal spent = monthlySpend(userId);
        return new BudgetDTO(request.monthlyLimit(), spent, request.monthlyLimit().subtract(spent));
    }

    private String defaultCurrencyFor(UUID userId) {
        return walletRepository.findByUserIdAndIsDefaultTrue(userId)
                .map(Wallet::getCurrencyCode)
                .orElseGet(() -> walletRepository.findByUserId(userId).stream()
                        .findFirst().map(Wallet::getCurrencyCode).orElse("USD"));
    }

    // ========================================================================
    // INSIGHTS
    // ========================================================================

    @Transactional(readOnly = true)
    public InsightsDTO getInsights(UUID userId) {
        Map<String, Boolean> creditByType = transactionTypeRepository.findAll().stream()
                .collect(Collectors.toMap(TransactionType::getTypeCode, TransactionType::isCredit));

        List<Transaction> thisMonth = transactionsThisMonth(userId);

        BigDecimal spend = thisMonth.stream()
                .filter(t -> !creditByType.getOrDefault(t.getTypeCode(), false))
                .filter(t -> "SUCCESS".equals(t.getStatus()))
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal income = thisMonth.stream()
                .filter(t -> creditByType.getOrDefault(t.getTypeCode(), false))
                .filter(t -> "SUCCESS".equals(t.getStatus()))
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<String, BigDecimal> byCategory = thisMonth.stream()
                .filter(t -> !creditByType.getOrDefault(t.getTypeCode(), false))
                .filter(t -> "SUCCESS".equals(t.getStatus()))
                .collect(Collectors.groupingBy(Transaction::getTypeCode, Collectors.reducing(BigDecimal.ZERO, Transaction::getAmount, BigDecimal::add)));

        List<CategoryAmountDTO> topCategories = byCategory.entrySet().stream()
                .sorted(Map.Entry.<String, BigDecimal>comparingByValue().reversed())
                .limit(5)
                .map(e -> new CategoryAmountDTO(e.getKey(), e.getValue()))
                .toList();

        return new InsightsDTO(spend, income, topCategories);
    }

    private BigDecimal monthlySpend(UUID userId) {
        Map<String, Boolean> creditByType = transactionTypeRepository.findAll().stream()
                .collect(Collectors.toMap(TransactionType::getTypeCode, TransactionType::isCredit));
        return transactionsThisMonth(userId).stream()
                .filter(t -> !creditByType.getOrDefault(t.getTypeCode(), false))
                .filter(t -> "SUCCESS".equals(t.getStatus()))
                .map(Transaction::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }

    private List<Transaction> transactionsThisMonth(UUID userId) {
        LocalDate today = LocalDate.now();
        LocalDateTime monthStart = today.withDayOfMonth(1).atStartOfDay();
        return transactionRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .filter(t -> t.getCreatedAt() != null && !t.getCreatedAt().isBefore(monthStart))
                .toList();
    }

    private Transaction recordTransaction(UUID userId, UUID walletId, String typeCode, BigDecimal amount,
                                           String currencyCode, String description) {
        Transaction transaction = new Transaction();
        transaction.setUserId(userId);
        transaction.setWalletId(walletId);
        transaction.setTypeCode(typeCode);
        transaction.setAmount(amount);
        transaction.setCurrencyCode(currencyCode);
        transaction.setStatus("SUCCESS");
        transaction.setReference(typeCode + "-" + UUID.randomUUID().toString().substring(0, 12).toUpperCase());
        transaction.setDescription(description);
        return transactionRepository.save(transaction);
    }
}
