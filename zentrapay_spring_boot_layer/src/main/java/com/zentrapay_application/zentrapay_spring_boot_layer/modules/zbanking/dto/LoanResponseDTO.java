package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record LoanResponseDTO(
        UUID loanId,
        BigDecimal principalAmount,
        BigDecimal interestRate,
        int termMonths,
        BigDecimal outstandingBalance,
        String status,
        LocalDate dueDate
) {
}
