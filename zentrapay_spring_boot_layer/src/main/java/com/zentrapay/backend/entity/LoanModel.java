package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

// Represents a ZLoan micro-loan application and its active/repayment lifecycle.
@Entity
@Data
@Table(
        name = "loans",
        uniqueConstraints = {
                // Ensures a single disbursement transaction cannot be attached to multiple loans.
                @UniqueConstraint(
                        name = "uk_loans_disbursement_txn",
                        columnNames = {"disbursement_transaction_id"}
                )
        },
        indexes = {
                // Speeds up lookups for a user's active, pending, or historical loans.
                @Index(
                        name = "idx_loans_user_status",
                        columnList = "user_id, status"
                ),
                // Speeds up scheduled jobs checking upcoming or overdue loans.
                @Index(
                        name = "idx_loans_status_due_date",
                        columnList = "status, due_date"
                )
        }
)
public class LoanModel {

    // Primary identifier for the loan record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Applicant / borrower user ID.
    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    // ISO currency code for the loan (e.g., KES, NGN, GHS).
    @Column(name = "currency_code", nullable = false, length = 3, updatable = false)
    private String currencyCode;

    // Original loan amount requested/disbursed.
    @Column(name = "principal_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal principalAmount;

    // Annual interest rate expressed as a decimal fraction (e.g., 0.1200 for 12%).
    @Column(name = "interest_rate", nullable = false, precision = 6, scale = 4)
    private BigDecimal interestRate;

    // Loan duration in months.
    @Column(name = "term_months", nullable = false)
    private short termMonths;

    // Remaining balance owed (principal + accrued interest/fees minus repayments).
    @Column(name = "outstanding_balance", nullable = false, precision = 19, scale = 4)
    private BigDecimal outstandingBalance;

    // Lifecycle state of the loan (PENDING, APPROVED, REJECTED, ACTIVE, CLOSED, DEFAULTED).
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    private Datatypes.LoanStatus status = Datatypes.LoanStatus.PENDING;

    // Cumulative amount repaid toward this loan so far.
    @Column(name = "repaid_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal repaidAmount = BigDecimal.ZERO;

    // Timestamp when the loan was fully paid off and closed.
    @Column(name = "closed_at")
    private LocalDateTime closedAt;

    // Wallet transaction ID created when the approved loan was disbursed.
    @Column(name = "disbursement_transaction_id")
    private UUID disbursementTransactionId;

    // Timestamp when the loan application was submitted.
    @CreationTimestamp
    @Column(name = "applied_at", nullable = false, updatable = false)
    private LocalDateTime appliedAt;

    // Timestamp when the loan application was approved.
    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    // Final repayment due date once disbursed/activated.
    @Column(name = "due_date")
    private LocalDate dueDate;

    // Stated reason for the loan (e.g., EMERGENCY, BUSINESS, PERSONAL).
    @Column(name = "purpose", length = 30)
    private String purpose;

    // Applicant's employment category (e.g., EMPLOYED, SELF_EMPLOYED, UNEMPLOYED).
    @Column(name = "employment_status", length = 30)
    private String employmentStatus;

    // Name of the applicant's employer or business.
    @Column(name = "employer_name", length = 120)
    private String employerName;

    // Applicant's job role or title.
    @Column(name = "job_title", length = 80)
    private String jobTitle;

    // Declared monthly income used for affordability assessment.
    @Column(name = "monthly_income", precision = 19, scale = 4)
    private BigDecimal monthlyIncome;

    // Declared recurring monthly debt/expense obligations.
    @Column(name = "monthly_obligations", precision = 19, scale = 4)
    private BigDecimal monthlyObligations;

    // Full name of the applicant's next of kin.
    @Column(name = "next_of_kin_name", length = 120)
    private String nextOfKinName;

    // Relationship of the next of kin to the applicant.
    @Column(name = "next_of_kin_relationship", length = 40)
    private String nextOfKinRelationship;

    // Phone number of the next of kin.
    @Column(name = "next_of_kin_phone", length = 20)
    private String nextOfKinPhone;

    // Explicit consent to perform credit/affordability checks.
    @Column(name = "credit_check_consent", nullable = false)
    private boolean creditCheckConsent;

    // Explicit acceptance of loan terms and conditions at submission.
    @Column(name = "terms_accepted", nullable = false)
    private boolean termsAccepted;

    // Internal underwriting risk grade assigned at review (e.g., A or B).
    @Column(name = "risk_grade", length = 2)
    private String riskGrade;

    // Optional underwriting approval or rejection reason.
    @Column(name = "decision_note", length = 255)
    private String decisionNote;

    // Optimistic locking version to prevent concurrent balance/repayment race conditions.
    @Version
    @Column(name = "version", nullable = false)
    private Long version;

    // Record creation timestamp.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Automatically updated whenever the loan record changes.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}