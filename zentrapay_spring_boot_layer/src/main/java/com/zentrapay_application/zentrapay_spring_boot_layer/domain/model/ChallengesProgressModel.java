package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

// Historical ledger tracking each incremental savings contribution
@Entity
@Table(name = "challenges_progress")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChallengesProgressModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_challenge_id", nullable = false)
    private UserChallengesModel userChallenge;

    @Column(name = "amount_contributed", nullable = false, precision = 19, scale = 4)
    private BigDecimal amountContributed;

    @Column(name = "new_total_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal newTotalAmount;

    @Column(name = "transaction_reference")
    private UUID transactionReference;

    @Column(length = 255)
    private String notes;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}