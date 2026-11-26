package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.UserCardModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface SavedCardRepository extends JpaRepository<UserCardModel, UUID> {

    List<UserCardModel> findByUserIdAndStatusOrderByIsDefaultDescCreatedAtDesc(UUID userId, String status);

    Optional<UserCardModel> findByIdAndUserId(UUID id, UUID userId);

    Optional<UserCardModel> findByUserIdAndGatewayAndSignature(UUID userId, String gateway, String signature);

    long countByUserIdAndStatus(UUID userId, String status);
}
