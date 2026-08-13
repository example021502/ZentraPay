package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.models;

import jakarta.persistence.*;
import lombok.Data;

import java.time.Instant;
import java.util.UUID;

@Entity
@Data
@Table(name = "user_funding_sources")
public class UserFundingSourcesModel {
    @Id
    @Column(name = "user_funding_source_id", nullable = false)
    private UUID userFundingSourceId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "source_id", nullable = false)
    private UUID sourceId;

    @Column(name = "is_primary", nullable = false)
    private boolean isPrimary;

    @Column(name = "linked_at", nullable = false)
    private Instant linkedAt;
}
