package com.zentrapay.backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * {@code user_services} (V18): a bill provider or service provider the user added to their Home screen.
 * {@code serviceKind} says which directory {@code providerId} belongs to.
 */
@Entity
@Data
@Table(name = "user_services")
public class UserServiceModel {

    public static final String BILL = "BILL";
    public static final String SERVICE = "SERVICE";

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "user_service_id", nullable = false, updatable = false)
    private UUID userServiceId;

    @Column(name = "user_id", nullable = false, updatable = false)
    private UUID userId;

    @Column(name = "service_kind", nullable = false, updatable = false, length = 10)
    private String serviceKind;

    @Column(name = "provider_id", nullable = false, updatable = false)
    private UUID providerId;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
