package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical mapping of {@code bill_providers} (V1__init_schema.sql). Single entity for
 * this table — the old codebase had a second, near-duplicate mapping under
 * searchContacts.model.SearchBillProvidersModel; that class has been removed and
 */
@Entity
@Data
@Table(name = "user_bill_providers")
public class UserBillProviderModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "user_bill_provider_id", nullable = false, unique = true)
    private UUID userBillProviderId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "provider_id", nullable = false)
    private UUID providerId;

    @Column(name = "account_reference", nullable = false, length = 120)
    private String accountReference;

    @CreationTimestamp
    @Column(name = "linked_at", nullable = false)
    private LocalDateTime linkedAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

}
