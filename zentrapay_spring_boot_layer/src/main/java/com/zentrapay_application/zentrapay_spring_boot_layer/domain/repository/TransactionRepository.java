package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<TransactionModel, UUID> {
    Page<TransactionModel> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);
    Page<TransactionModel> findByUserIdAndTypeCodeOrderByCreatedAtDesc(UUID userId, String typeCode, Pageable pageable);
    Page<TransactionModel> findByUserIdAndStatusOrderByCreatedAtDesc(UUID userId, String status, Pageable pageable);
    List<TransactionModel> findByUserIdOrderByCreatedAtDesc(UUID userId);
    Optional<TransactionModel> findByTransactionIdAndUserId(UUID transactionId, UUID userId);
    Optional<TransactionModel> findByReference(String reference);
}
