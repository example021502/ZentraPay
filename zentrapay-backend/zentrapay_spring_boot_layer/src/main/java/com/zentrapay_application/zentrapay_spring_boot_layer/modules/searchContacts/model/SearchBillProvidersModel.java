package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.model;

import jakarta.persistence.*;
import lombok.Data;

// FIAT CURRENCY DATA
@Entity
@Table(name = "bill_providers")
@Data // Requires Lombok dependency
public class SearchBillProvidersModel {
    @Id
    @Column(nullable = false, name = "provider_id", unique = true)
    private String providerId;

    @Column(nullable = false, name = "biller_id")
    private String billerId;

    @Column(nullable = false, name = "biller_name")
    private String billerName;

    private String userType = "bill provider";

    @Column(nullable = false, name = "category")
    private String category;

    @Column(nullable = false, name = "customer_params_schema")
    private String customerParamsSchema;


    @Column(nullable = false, name = "fetch_requirement")
    private String fetchRequirement; // Stores bcrypt hash

    @Column(nullable = false, name = "status")
    private String status;      // Stores bcrypt hash
}
