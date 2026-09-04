package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<TransactionModel, UUID> {
    @Query("SELECT t FROM TransactionModel t WHERE " +
            "(t.senderId = :userId AND t.transactionType = 'debit') OR " +
            "(t.receiverId = :userId AND t.transactionType = 'credit') " +
            "ORDER BY t.createdAt DESC")
    Page<TransactionModel> findUserHistory(UUID userId, Pageable pageable);

    // Webhook status-sync lookups — every gateway call is journaled with our
    // own reference as internalReferenceId, and (once accepted) the
    // gateway's own code as externalReferenceId.
    Optional<TransactionModel> findByInternalReferenceId(String internalReferenceId);

    Optional<TransactionModel> findByExternalReferenceId(String externalReferenceId);
}
