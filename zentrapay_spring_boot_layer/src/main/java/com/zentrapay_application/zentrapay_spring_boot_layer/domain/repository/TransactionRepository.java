package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<TransactionModel, UUID> {
    Page<TransactionModel> findBySenderIdOrderByCreatedAtDesc(UUID senderId, Pageable pageable);
    Page<TransactionModel> findBySenderIdAndTransactionTypeOrderByCreatedAtDesc(UUID senderId, String transactionType, Pageable pageable);
    Page<TransactionModel> findBySenderIdAndStatusOrderByCreatedAtDesc(UUID senderId, String status, Pageable pageable);
    List<TransactionModel> findBySenderIdOrderByCreatedAtDesc(UUID senderId);
    Optional<TransactionModel> findByTransactionIdAndSenderId(UUID transactionId, UUID senderId);
    Optional<TransactionModel> findByInternalReferenceId(String internalReferenceId);
}
