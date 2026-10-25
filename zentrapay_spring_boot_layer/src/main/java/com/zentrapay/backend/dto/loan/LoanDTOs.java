package com.zentrapay.backend.dto.loan;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Request / response shapes of the micro-loan endpoints (/api/zbanking/loans/*).
 */
public final class LoanDTOs {

    private LoanDTOs() {
    }

    /**
     * POST /apply body - everything a lender needs for a micro-loan decision.
     * Identity and address are NOT asked again: they come from the user's
     * verified KYC profile.
     */
    public record LoanApplicationRequestDTO(
            BigDecimal amount,
            String currencyCode,
            Integer termMonths,
            /** BUSINESS, EDUCATION, MEDICAL, RENT, EMERGENCY, PERSONAL, OTHER */
            String purpose,
            /** EMPLOYED, SELF_EMPLOYED, STUDENT, RETIRED, UNEMPLOYED */
            String employmentStatus,
            String employerName,
            String jobTitle,
            BigDecimal monthlyIncome,
            /** Rent, other loans, school fees ... paid every month already. */
            BigDecimal monthlyObligations,
            String nextOfKinName,
            String nextOfKinRelationship,
            String nextOfKinPhone,
            Boolean creditCheckConsent,
            Boolean termsAccepted
    ) {
    }

    /** One loan / application. */
    public record LoanDTO(
            UUID loanId,
            String currencyCode,
            BigDecimal principalAmount,
            BigDecimal interestRate,
            Integer termMonths,
            BigDecimal outstandingBalance,
            BigDecimal monthlyInstallment,
            String status,
            String purpose,
            LocalDate dueDate,
            LocalDateTime appliedAt,
            String decisionNote
    ) {
    }

    /**
     * GET /eligibility - what this user may borrow and, when they may not, why.
     * {@code grade} is the lender's risk grade (A better than B), {@code null}
     * when the user is not eligible.
     */
    public record LoanEligibilityDTO(
            boolean eligible,
            int kycTier,
            String grade,
            String currencyCode,
            BigDecimal minAmount,
            BigDecimal maxAmount,
            int maxTermMonths,
            BigDecimal interestRate,
            List<String> requirements
    ) {
    }
}
