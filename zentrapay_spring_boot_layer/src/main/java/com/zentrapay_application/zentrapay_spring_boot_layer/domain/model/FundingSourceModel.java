package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical fiat wallet — consolidates the old fiat_currency_accounts /
 * fiat_currencies / user_wallets (x2 conflicting mappings).
 */
@Entity
@Data
@Table(name = "funding_sources")
public class FundingSourceModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "source_id", nullable = false)
    private UUID sourceId;

    @Column(name = "account_identifier", nullable = false, length = 60)
    private String accountIdentifier;

    @Column(name = "channel_code", nullable = false, length = 3)
    private String channelCode;

    @Column(name = "country_code", length = 3)
    private String countryCode;

    @Column(name = "is_verified", nullable = false)
    private boolean isVerified;

    @Column(name = "source_name", nullable = false)
    private String sourceName;

    @Column(name = "source_type", nullable = false)
    private String sourceType;

    @Column(name = "account_name", nullable = false)
    private String accountName;

    @Column(name = "funding_source_code", nullable = false)
    private String fundingSourceCode;

    @Column(name = "currency", nullable = false)
    private String currency;

    @Column(name = "funding_type", nullable = false)
    private String fundingType;

    @Column(name = "is_primary", nullable = false)
    private Boolean isPrimary;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
