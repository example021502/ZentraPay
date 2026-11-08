package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.InvestmentPriceSnapshotModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface InvestmentPriceSnapshotRepository extends JpaRepository<InvestmentPriceSnapshotModel, UUID> {

    // The newest recorded price = the current price of the position
    Optional<InvestmentPriceSnapshotModel> findFirstByInvestmentIdOrderByRecordedAtDesc(UUID investmentId);
}
