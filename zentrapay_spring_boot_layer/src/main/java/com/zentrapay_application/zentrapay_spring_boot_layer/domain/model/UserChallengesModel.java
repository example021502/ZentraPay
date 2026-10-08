package com.zentrapay_application.zentrapay_spring_boot_layer.domain.model;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

// Active user participation record for a challenge
@Entity
@Table(
        name = "user_challenges",
        uniqueConstraints = {
                @UniqueConstraint(name = "unique_user_active_challenge", columnNames = {"user_id", "challenge_id"})
        }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserChallengesModel {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "challenge_id", nullable = false)
    private ChallengesModel challenge;

    @Enumerated(EnumType.STRING)
    @Column(name="status", nullable = false, length = 30)
    private Datatypes.ChallengeStatus status;

    @Builder.Default
    @Column(name = "current_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal currentAmount = BigDecimal.ZERO;

    @Column(name = "target_amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal targetAmount;

    @Column(name = "started_at", nullable = false)
    private LocalDateTime startedAt;

    @Column(name = "ends_at", nullable = false)
    private LocalDateTime endsAt;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Builder.Default
    @OneToMany(mappedBy = "userChallenge", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    private List<ChallengesProgressModel> progressLogs = new ArrayList<>();
}