package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zvoice.model;

import jakarta.persistence.*;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "voice_commands")
public class VoiceCommandModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "command_id", nullable = false, unique = true)
    private UUID commandId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Column(name = "command_type", nullable = false, length = 20)
    private String commandType; // VOICE, CHAT

    @Column(nullable = false, length = 10)
    private String language = "en";

    @Column(nullable = false, columnDefinition = "TEXT")
    private String transcript;

    @Column(name = "response_text", columnDefinition = "TEXT")
    private String responseText;

    @Column(nullable = false, length = 20)
    private String status = "PROCESSED"; // PROCESSED, FAILED, PENDING

    @Column(name = "fraud_alert", nullable = false)
    private boolean fraudAlert = false;

    @Column(name = "fraud_reason", columnDefinition = "TEXT")
    private String fraudReason;

    @CreationTimestamp
    @Column(nullable = false, name = "created_at")
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(nullable = false, name = "updated_at")
    private LocalDateTime updatedAt;

    // Getters and Setters
    public UUID getCommandId() { return commandId; }
    public void setCommandId(UUID commandId) { this.commandId = commandId; }
    public UUID getUserId() { return userId; }
    public void setUserId(UUID userId) { this.userId = userId; }
    public String getCommandType() { return commandType; }
    public void setCommandType(String commandType) { this.commandType = commandType; }
    public String getLanguage() { return language; }
    public void setLanguage(String language) { this.language = language; }
    public String getTranscript() { return transcript; }
    public void setTranscript(String transcript) { this.transcript = transcript; }
    public String getResponseText() { return responseText; }
    public void setResponseText(String responseText) { this.responseText = responseText; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public boolean isFraudAlert() { return fraudAlert; }
    public void setFraudAlert(boolean fraudAlert) { this.fraudAlert = fraudAlert; }
    public String getFraudReason() { return fraudReason; }
    public void setFraudReason(String fraudReason) { this.fraudReason = fraudReason; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
