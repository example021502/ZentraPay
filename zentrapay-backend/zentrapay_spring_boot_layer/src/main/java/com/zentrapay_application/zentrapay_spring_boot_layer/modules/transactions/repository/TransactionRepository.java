package com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.model.TransactionModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface TransactionRepository extends JpaRepository<TransactionModel, UUID> {
    List<TransactionModel> findByUserId(UUID userId);
    List<TransactionModel> findByUserIdAndStatus(UUID userId, String status);
    List<TransactionModel> findByUserIdAndGateway(UUID userId, String gateway);
    List<TransactionModel> findByUserIdAndTransactionType(UUID userId, String transactionType);
}