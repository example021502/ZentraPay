package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.RemittanceModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RemittancesRepository extends JpaRepository<RemittanceModel, UUID> {

    List<RemittanceModel> findBySenderIdOrderByCreatedAtDesc(UUID senderId);
}