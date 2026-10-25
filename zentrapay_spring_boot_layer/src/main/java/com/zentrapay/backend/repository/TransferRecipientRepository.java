package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.TransferRecipientModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TransferRecipientRepository extends JpaRepository<TransferRecipientModel, UUID> {

    /** Dedupe lookups so re-saving the same bank account/momo wallet reuses the row. */
    Optional<TransferRecipientModel> findByUserIdAndDestinationTypeAndAccountIdentifier(
            UUID userId, String destinationType, String accountIdentifier);

    List<TransferRecipientModel> findByUserIdOrderByCreatedAtDesc(UUID userId);
}