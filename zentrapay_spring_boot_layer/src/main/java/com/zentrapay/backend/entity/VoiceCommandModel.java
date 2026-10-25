package com.zentrapay.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * One spoken (VOICE) or typed (CHAT) instruction given to ZVoice AI, with the reply that was given.
 * Mapping of {@code voice_commands} (V5, extended by V12). This table is the user's ZVoice history.
 */
@Entity
@Data
@Table(name = "voice_commands")
public class VoiceCommandModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "command_id", nullable = false)
    private UUID commandId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /** VOICE (spoken) or CHAT (typed). */
    @Column(name = "command_type", nullable = false, length = 20)
    private String commandType;

    @Column(name = "language", nullable = false, length = 10)
    private String language = "en";

    @Column(name = "transcript", nullable = false, columnDefinition = "TEXT")
    private String transcript;

    @Column(name = "response_text", columnDefinition = "TEXT")
    private String responseText;

    /** PROCESSED, or FLAGGED when the instruction looked like fraud. */
    @Column(name = "status", nullable = false, length = 20)
    private String status = "PROCESSED";

    @Column(name = "fraud_alert", nullable = false)
    private boolean fraudAlert;

    @Column(name = "fraud_reason", columnDefinition = "TEXT")
    private String fraudReason;

    /** What the instruction was about: BALANCE, SEND_MONEY, PAY_BILL, HISTORY, SECURITY, HELP, GREETING, UNKNOWN. */
    @Column(name = "intent", length = 40)
    private String intent;

    /** How long the user spoke, in milliseconds (VOICE only). */
    @Column(name = "duration_ms")
    private Integer durationMs;

    /** How sure the speech recogniser was, 0 to 1 (VOICE only). */
    @Column(name = "confidence", precision = 4, scale = 3)
    private BigDecimal confidence;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
}
