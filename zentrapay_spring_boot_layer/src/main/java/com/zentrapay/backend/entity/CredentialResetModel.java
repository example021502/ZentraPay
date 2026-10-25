package com.zentrapay.backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Data;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
import java.util.UUID;

/**
 * A "forgot password" / "forgot PIN" request (V12). Only hashes are stored: the emailed code and the
 * reset token that the code is exchanged for can never be read back from the database.
 */
@Entity
@Data
@Table(name = "credential_reset_requests")
public class CredentialResetModel {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "request_id", nullable = false)
    private UUID requestId;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    /** PASSWORD or PIN. */
    @Column(name = "purpose", nullable = false, length = 10)
    private String purpose;

    @Column(name = "code_hash", nullable = false, length = 128)
    private String codeHash;

    /** Wrong codes tried so far; the request is dead after too many. */
    @Column(name = "attempts", nullable = false)
    private int attempts;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    /** Set when the emailed code was entered correctly. */
    @Column(name = "verified_at")
    private LocalDateTime verifiedAt;

    @Column(name = "reset_token_hash", length = 128)
    private String resetTokenHash;

    @Column(name = "reset_token_expires_at")
    private LocalDateTime resetTokenExpiresAt;

    /** Set when the new password / PIN was saved, or the request was replaced by a newer one. */
    @Column(name = "used_at")
    private LocalDateTime usedAt;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;
}
