package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {
    Page<Transaction> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);
    Page<Transaction> findByUserIdAndTypeCodeOrderByCreatedAtDesc(UUID userId, String typeCode, Pageable pageable);
    Page<Transaction> findByUserIdAndStatusOrderByCreatedAtDesc(UUID userId, String status, Pageable pageable);
    List<Transaction> findByUserIdOrderByCreatedAtDesc(UUID userId);
    Optional<Transaction> findByTransactionIdAndUserId(UUID transactionId, UUID userId);
    Optional<Transaction> findByReference(String reference);
}
