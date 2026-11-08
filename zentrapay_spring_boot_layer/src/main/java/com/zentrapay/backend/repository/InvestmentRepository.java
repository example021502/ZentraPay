package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.InvestmentModel;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface InvestmentRepository extends JpaRepository<InvestmentModel, UUID> {

    List<InvestmentModel> findByUserIdOrderByCreatedAtDesc(UUID userId);

    // Selling reads the position WITH a lock so two taps at once cannot pay the proceeds out twice
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM InvestmentModel i WHERE i.investmentId = :id AND i.userId = :userId")
    Optional<InvestmentModel> findOwnedForUpdate(@Param("id") UUID id, @Param("userId") UUID userId);
}
