package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zgrow.model.PointsLedger;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface PointsLedgerRepository extends JpaRepository<PointsLedger, UUID> {
    List<PointsLedger> findByUserIdOrderByCreatedAtDesc(UUID userId, Pageable pageable);
}
