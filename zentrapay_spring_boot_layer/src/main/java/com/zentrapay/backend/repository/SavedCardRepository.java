package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.SavedCardModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SavedCardRepository extends JpaRepository<SavedCardModel, UUID> {

    List<SavedCardModel> findByUserIdAndStatusOrderByIsDefaultDescCreatedAtDesc(UUID userId, String status);

    Optional<SavedCardModel> findByIdAndUserId(UUID id, UUID userId);

    Optional<SavedCardModel> findByUserIdAndGatewayAndSignature(UUID userId, String gateway, String signature);

    long countByUserIdAndStatus(UUID userId, String status);
}
