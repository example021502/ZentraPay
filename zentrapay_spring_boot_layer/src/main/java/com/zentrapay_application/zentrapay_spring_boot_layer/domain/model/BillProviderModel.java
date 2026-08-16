package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Canonical mapping of {@code bill_providers} (V1__init_schema.sql). Single entity for
 * this table — the old codebase had a second, near-duplicate mapping under
 * searchContacts.model.SearchBillProvidersModel; that class has been removed and
 */
@Entity
@Data
@Table(name = "bill_providers")
public class BillProviderModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "provider_id", nullable = false)
    private UUID providerId;

    @Column(name = "biller_code", nullable = false, unique = true, length = 40)
    private String billerCode;

    @Column(name = "biller_name", nullable = false, length = 120)
    private String billerName;

    @Column(name = "category_code", nullable = false, length = 30)
    private String categoryCode;

    @Column(name = "country_code", nullable = false, length = 2)
    private String countryCode;

    @Column(name = "channel_code", nullable = false)
    private String channelCode;

    @Column(name = "is_crossborder_allowed", nullable = false)
    private Boolean isCrossBorderAllowed;

    @Column(name = "logo_url", columnDefinition = "TEXT")
    private String logoUrl;

    @Column(name = "active", nullable = false)
    private Boolean active;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "fetch_requirement", columnDefinition = "jsonb")
    private List<Map<String, Object>> fetchRequirement;

    @Column(name = "customer_params_schema")
    private String customerParamsSchema;

    @Transient
    private String userType = "bill-provider";

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;


}
