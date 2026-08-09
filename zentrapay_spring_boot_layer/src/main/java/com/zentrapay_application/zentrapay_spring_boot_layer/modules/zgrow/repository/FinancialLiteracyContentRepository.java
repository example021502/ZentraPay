package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.FinancialLiteracyContent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface FinancialLiteracyContentRepository extends JpaRepository<FinancialLiteracyContent, UUID> {
    List<FinancialLiteracyContent> findByIsActiveTrue();
}
