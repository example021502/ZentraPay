package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.model.TransactionModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TransactionRepository extends JpaRepository<TransactionModel, Long> {
}