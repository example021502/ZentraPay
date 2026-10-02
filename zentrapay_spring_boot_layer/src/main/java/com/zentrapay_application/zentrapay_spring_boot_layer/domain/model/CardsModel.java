package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Canonical card — consolidates the old cards.CardsModel and
 * zpay.CardModel (both mapped "cards" with different, incompatible columns).
 */
@Entity
@Data
@Table(name = "cards")
public class CardsModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "card_id", nullable = false)
    private UUID cardId;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "brand", nullable=false)
    private String brand;

    @Column(name = "card_type", nullable = false, length = 20)
    private String cardType = "VIRTUAL"; // VIRTUAL, PHYSICAL

    @Column(name = "description")
    private String description;

    @Column(name = "active", nullable = false)
    private Boolean active;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
