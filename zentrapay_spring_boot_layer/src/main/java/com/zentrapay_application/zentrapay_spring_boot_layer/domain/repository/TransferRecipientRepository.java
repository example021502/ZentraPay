package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransferRecipientModel;
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