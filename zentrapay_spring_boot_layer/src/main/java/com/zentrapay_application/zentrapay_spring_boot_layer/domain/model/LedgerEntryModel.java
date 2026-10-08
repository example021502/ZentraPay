// Always put comments on all responses.
package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data // Automatically generates getters, setters, equals, hashCode, and toString
@Builder
@NoArgsConstructor
@AllArgsConstructor
@Table(
        name = "ledger_entries",
        indexes = {
                @Index(name = "idx_ledger_account_created", columnList = "account_id, created_at DESC"),
                @Index(name = "idx_ledger_transaction", columnList = "transaction_id")
        }
)
public class LedgerEntryModel {

    // Primary Key
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "ledger_id", nullable = false, updatable = false)
    private UUID ledgerId;

    // Direct reference to the parent transaction ID
    @Column(name = "transaction_id", nullable = false, updatable = false)
    private UUID transactionId;

    // Unique Entry ID containing -DEBIT or -CREDIT suffix
    @Column(name = "entry_id", nullable = false, unique = true, length = 64, updatable = false)
    private String entryId;

    // Wallet or Account ID being affected
    @Column(name = "account_id", nullable = false, updatable = false)
    private UUID accountId;

    // Enum representing DEBIT or CREDIT
    @Enumerated(EnumType.STRING)
    @Column(name = "type", nullable = false, length = 10, updatable = false)
    private Datatypes.LedgerEntryType type;

    // Transaction amount for this entry
    @Column(name = "amount", nullable = false, precision = 19, scale = 4, updatable = false)
    private BigDecimal amount;

    // Historical balance snapshot immediately after this entry was applied
    @Column(name = "running_balance", nullable = false, precision = 19, scale = 4, updatable = false)
    private BigDecimal runningBalance;

    // Currency code (e.g., GHS)
    @Column(name = "currency_code", nullable = false, length = 3, updatable = false)
    private String currencyCode;

    // Brief explanation (e.g., "Transfer to Ama - Outbound")
    @Column(name = "narration", nullable = false, length = 255, updatable = false)
    private String narration;

    // Timestamp when entry was posted
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}