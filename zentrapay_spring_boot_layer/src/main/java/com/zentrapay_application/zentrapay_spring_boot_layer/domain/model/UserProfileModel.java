package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "user_profiles")
public class UserProfileModel {
    @Id
    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "date_of_birth")
    private LocalDate dateOfBirth;

    @Column(name = "id_document_type", length = 30)
    private String idDocumentType;

    @Column(name = "id_document_number", length = 60)
    private String idDocumentNumber;

    @Column(name = "id_document_country_code", length = 2)
    private String idDocumentCountryCode;

    @Column(name = "address_line1", length = 120)
    private String addressLine1;

    @Column(name = "address_line2", length = 120)
    private String addressLine2;

    @Column(length = 60)
    private String city;

    @Column(name = "region_state", length = 60)
    private String regionState;

    @Column(name = "postal_code", length = 20)
    private String postalCode;

    @Column(length = 80)
    private String occupation;

    @Column(name = "aml_status", nullable = false, length = 20)
    private String amlStatus = "CLEAR";

    @Column(name = "is_pep", nullable = false)
    private boolean isPep;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
