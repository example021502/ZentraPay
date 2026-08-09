package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code loan_repayments} (V1__init_schema.sql).
 */
@Entity
@Data
@Table(name = "loan_repayments")
public class LoanRepayment {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "repayment_id", nullable = false)
    private UUID repaymentId;

    @Column(name = "loan_id", nullable = false)
    private UUID loanId;

    @Column(name = "transaction_id", nullable = false, unique = true)
    private UUID transactionId;

    @Column(nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @CreationTimestamp
    @Column(name = "paid_at", nullable = false)
    private LocalDateTime paidAt;
}
