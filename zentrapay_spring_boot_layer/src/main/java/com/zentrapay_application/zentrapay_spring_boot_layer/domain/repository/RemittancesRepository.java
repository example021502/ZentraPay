package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.RemittanceModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RemittancesRepository extends JpaRepository<RemittanceModel, UUID> {

    List<RemittanceModel> findBySenderIdOrderByCreatedAtDesc(UUID senderId);
}