package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.TransactionModel;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.UUID;

public interface TransactionRepository extends JpaRepository<TransactionModel, UUID> {
    @Query("SELECT t FROM TransactionModel t WHERE t.senderId = :userId OR t.receiverId = :userId ORDER BY t.createdAt DESC")
    Page<TransactionModel> findBySenderIdOrReceiverId(UUID userId, Pageable pageable);
}
