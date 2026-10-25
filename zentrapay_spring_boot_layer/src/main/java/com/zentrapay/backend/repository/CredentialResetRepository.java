package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.CredentialResetModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CredentialResetRepository extends JpaRepository<CredentialResetModel, UUID> {

    // The newest request that has not been used yet
    Optional<CredentialResetModel> findFirstByUserIdAndPurposeAndUsedAtIsNullOrderByCreatedAtDesc(UUID userId, String purpose);

    // Requests still open (used to retire them when a newer one is made)
    List<CredentialResetModel> findByUserIdAndPurposeAndUsedAtIsNull(UUID userId, String purpose);

    // How many codes were asked for recently (rate limit)
    long countByUserIdAndPurposeAndCreatedAtAfter(UUID userId, String purpose, LocalDateTime since);
}
