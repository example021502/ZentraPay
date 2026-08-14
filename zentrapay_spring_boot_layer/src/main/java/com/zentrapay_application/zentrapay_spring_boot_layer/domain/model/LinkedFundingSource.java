package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "funding_sources")
public class LinkedFundingSource {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "source_id", nullable = false)
    private UUID sourceId;

    @Column(name = "source_type", nullable = false, length = 20)
    private String sourceType;

    @Column(name = "source_name", nullable = false, length = 120)
    private String sourceName;

    @Column(name = "account_identifier", nullable = false, length = 60)
    private String accountIdentifier;

    @Column(name = "channel_code")
    private String channelCode;

    @Transient
    private String userType = "funding-source";

    @Column(name = "country_code", nullable = false, length = 3)
    private String countryCode;

    @Column(name = "is_verified", nullable = false)
    private boolean isVerified;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
