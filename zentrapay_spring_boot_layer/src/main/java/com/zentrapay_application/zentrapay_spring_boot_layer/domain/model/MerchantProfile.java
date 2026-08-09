package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "merchant_profiles")
public class MerchantProfile {
    @Id
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "business_name", nullable = false, length = 120)
    private String businessName;

    @Column(name = "business_registration_number", length = 60)
    private String businessRegistrationNumber;

    @Column(name = "tax_identification_number", length = 60)
    private String taxIdentificationNumber;

    @Column(name = "business_category_code", length = 30)
    private String businessCategoryCode;

    @Column(name = "business_country_code", nullable = false, length = 2)
    private String businessCountryCode;

    @Column(name = "business_address", length = 200)
    private String businessAddress;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
