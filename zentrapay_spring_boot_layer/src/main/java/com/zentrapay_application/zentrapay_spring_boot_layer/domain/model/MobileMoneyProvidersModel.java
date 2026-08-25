package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@Table(name = "momo_providers")
public class MobileMoneyProvidersModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "provider_id", nullable = false)
    private UUID providerId;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "global_code", nullable = false, length = 30)
    private String globalCode;

    @Column(name = "countryCode", nullable = false, length = 3)
    private String countryCode;

    @Column(name = "active", nullable = false, length = 30)
    private Boolean active;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @CreationTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

}
