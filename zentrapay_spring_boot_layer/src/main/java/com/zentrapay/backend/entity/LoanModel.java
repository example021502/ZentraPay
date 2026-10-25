package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A micro-loan application and, once approved, the loan itself ({@code loans} table).
 * An application starts as PENDING; the columns after {@code dueDate} are what the
 * application form collects so the lender can assess affordability.
 */
@Entity
@Data
@Table(name = "loans")
public class LoanModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "loan_id", nullable = false)
    private UUID loanId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "currency_code", nullable = false, length = 8)
    private String currencyCode;

    @Column(name = "principal_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal principalAmount;

    /** Annual rate as a fraction, e.g. 0.1200 for 12%. */
    @Column(name = "interest_rate", nullable = false, precision = 6, scale = 4)
    private BigDecimal interestRate;

    @Column(name = "term_months", nullable = false)
    private short termMonths;

    @Column(name = "outstanding_balance", nullable = false, precision = 19, scale = 4)
    private BigDecimal outstandingBalance;

    // PENDING, APPROVED, REJECTED, ACTIVE, CLOSED, DEFAULTED
    @Column(name = "status", nullable = false, length = 20)
    private String status = "PENDING";

    @Column(name = "disbursement_transaction_id")
    private UUID disbursementTransactionId;

    @Column(name = "applied_at", nullable = false)
    private LocalDateTime appliedAt = LocalDateTime.now();

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "due_date")
    private LocalDate dueDate;

    @Column(name = "purpose", length = 30)
    private String purpose;

    @Column(name = "employment_status", length = 30)
    private String employmentStatus;

    @Column(name = "employer_name", length = 120)
    private String employerName;

    @Column(name = "job_title", length = 80)
    private String jobTitle;

    @Column(name = "monthly_income", precision = 19, scale = 4)
    private BigDecimal monthlyIncome;

    @Column(name = "monthly_obligations", precision = 19, scale = 4)
    private BigDecimal monthlyObligations;

    @Column(name = "next_of_kin_name", length = 120)
    private String nextOfKinName;

    @Column(name = "next_of_kin_relationship", length = 40)
    private String nextOfKinRelationship;

    @Column(name = "next_of_kin_phone", length = 20)
    private String nextOfKinPhone;

    @Column(name = "credit_check_consent", nullable = false)
    private boolean creditCheckConsent;

    @Column(name = "terms_accepted", nullable = false)
    private boolean termsAccepted;

    /** Lender's risk grade at the time of the application: A or B. */
    @Column(name = "risk_grade", length = 2)
    private String riskGrade;

    @Column(name = "decision_note", length = 255)
    private String decisionNote;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
