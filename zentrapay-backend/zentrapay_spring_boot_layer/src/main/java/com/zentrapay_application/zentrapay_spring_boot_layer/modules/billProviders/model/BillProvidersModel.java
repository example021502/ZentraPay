package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "bill_providers")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class BillProvidersModel {
    @Id
    @Column(nullable = false, name = "provider_id", unique = true)
    private String providerId;

    @Column(nullable = false, name = "biller_id")
    private String billerId;

    @Column(nullable = false, name = "biller_name")
    private String billerName;

    @Column(nullable = false, name = "category")
    private String category;

    @Column(nullable = false, name = "customer_params_schema")
    private String customerParamsSchema;


    @Column(nullable = false, name = "fetch_requirement")
    private String fetchRequirement; // Stores bcrypt hash

    @Column(nullable = false, name = "status")
    private String status;
}
