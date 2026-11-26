package com.zentrapay.backend.entity;

import com.zentrapay.backend.service.common.Datatypes;
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
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "code", nullable = false)
    private String code;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "category_code", nullable = false)
    private String categoryCode;

    @Column(name = "country_code", nullable = false, length = 3)
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

    @Column(name = "gateway", nullable = false)
    private Datatypes.Gateway gateway;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

}
