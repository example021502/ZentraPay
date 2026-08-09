package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Data
@Table(name = "provider_categories")
public class ProviderCategory {
    @Id
    @Column(name = "category_code", nullable = false, length = 30)
    private String categoryCode;

    @Column(name = "category_name", nullable = false, length = 60)
    private String categoryName;
}
