package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

/**
 * DTO for loan application.
 */
public record LoanRequestDTO(
        @NotBlank(message = "Loan type is required")
        String loanType,

        @NotNull(message = "Loan amount is required")
        @DecimalMin(value = "100.0", message = "Minimum loan amount is 100.0")
        BigDecimal amount,

        @NotNull(message = "Duration is required")
        Integer durationMonths,

        String purpose,

        @NotBlank(message = "Employment status is required")
        String employmentStatus,

        BigDecimal monthlyIncome
) {
}