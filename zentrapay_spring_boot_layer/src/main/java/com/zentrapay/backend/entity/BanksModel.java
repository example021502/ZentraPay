package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

// Stores bank and mobile-money channel metadata synced from payment gateways per currency/corridor.
@Entity
@Data
@Table(
        name = "banks",
        uniqueConstraints = @UniqueConstraint(
                // Prevents duplicate bank codes within the same gateway and currency scope.
                name = "uk_banks_gateway_code_currency",
                columnNames = {"gateway_id", "code", "currency_code"}
        )
)
public class BanksModel {

    // Primary identifier for the synced bank/channel record.
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    // Gateway-specific bank or channel code (matches GatewayRecipientsModel.channelCode).
    @Column(name = "code", nullable = false, length = 32)
    private String code;

    // Display name of the bank or mobile-money institution.
    @Column(name = "name", nullable = false)
    private String name;

    // Reference ID of the gateway (gateways.id) that provided this bank entry.
    @Column(name = "gateway", nullable = false)
    private Datatypes.Gateway gateway;

    // Optional IBAN when supported by the institution or corridor.
    @Column(name = "iban")
    private String iban;

    // ISO currency code such as KES, NGN, or GHS.
    @Column(name = "currency_code", nullable = false, length = 3)
    private String currencyCode;

    // Indicates whether direct bank/account payment is supported for this entry.
    @Column(name = "pay_with_bank")
    private Boolean payWithBank;

    // Optional SWIFT/BIC identifier where applicable.
    @Column(name = "swift_bic")
    private String swiftBic;

    // Optional country code (e.g., KE, NG, GH).
    @Column(name = "country_code", length = 3)
    private String countryCode;

    // Optional human-readable country name.
    @Column(name = "country")
    private String country;

    // Optional routing number (kept non-unique to avoid collisions across entries).
    @Column(name = "routing_number")
    private String routingNumber;

    // Institution or channel classification (e.g., bank, mobile_money).
    @Column(name = "type", length = 32)
    private String type;

    // Controls whether this bank/channel is currently available for selection and payouts.
    @Column(name = "active", nullable = false)
    private Datatypes.AccountStatus active = Datatypes.AccountStatus.ACTIVE;

    // Timestamp when the record was first created.
    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Timestamp automatically updated whenever the record changes.
    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    // Maximum cumulative daily amount allowed for this bank/channel.
    @Column(name = "max_daily_value", precision = 19, scale = 4)
    private BigDecimal maxDailyValue;

    // Maximum cumulative weekly amount allowed for this bank/channel.
    @Column(name = "max_weekly_value", precision = 19, scale = 4)
    private BigDecimal maxWeeklyValue;

    // Maximum cumulative monthly amount allowed for this bank/channel.
    @Column(name = "max_monthly_value", precision = 19, scale = 4)
    private BigDecimal maxMonthlyValue;

    // Minimum single-transaction amount allowed.
    @Column(name = "min_txn_limit", precision = 19, scale = 4)
    private BigDecimal minTxnLimit;

    // Maximum single-transaction amount allowed.
    @Column(name = "max_txn_limit", precision = 19, scale = 4)
    private BigDecimal maxTxnLimit;
}