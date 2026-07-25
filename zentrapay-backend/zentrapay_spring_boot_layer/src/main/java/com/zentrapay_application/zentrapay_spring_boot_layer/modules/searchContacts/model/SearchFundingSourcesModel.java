package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model;

import jakarta.persistence.*;
import lombok.Data;

// FIAT CURRENCY DATA
@Entity
@Table(name = "linked_funding_sources")
@Data // Requires Lombok dependency
public class SearchFundingSourcesModel {
    @Id
    @Column(nullable = false, name = "source_id", unique = true)
    private String sourceId;

    @Column(nullable = false, name = "user_id")
    private String userId;

    private String userType = "funding source";

    @Column(nullable = false, name = "funding_type")
    private String fundingType;

    @Column(nullable = false, name = "source_name")
    private String sourceName;

    @Column(nullable = false, name = "country_code")
    private String countryCode;

    @Column(nullable = false, name = "account_identifier")
    private String accountIdentifier;

    @Column(nullable = false, name = "account_name")
    private String accountName;

    @Column(nullable = false, name = "bank_code")
    private String bankCode;

    @Column(nullable = false, name = "currency")
    private String currency;

    @Column(nullable = false, name = "is_primary")
    private String isPrimary;

    @Column(nullable = false, name = "created_at")
    private String createdAt;
}
