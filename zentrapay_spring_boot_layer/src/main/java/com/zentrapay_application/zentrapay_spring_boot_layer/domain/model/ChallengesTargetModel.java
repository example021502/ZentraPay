package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

// Target milestone and reward payout entity
@Entity
@Table(name = "challenges_targets")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ChallengesTargetModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "challenge_id", nullable = false)
    private ChallengesModel challenge;

    @Column(name = "target_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal targetAmount;

    @Enumerated(EnumType.STRING)
    @Column(name = "reward_type", nullable = false, length = 50)
    private Datatypes.RewardType rewardType;

    @Column(name = "reward_value", nullable = false, length = 100)
    private String rewardValue;

    @Builder.Default
    @Column(name = "tier_level", nullable = false)
    private Integer tierLevel = 1;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
}