package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zpay.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zpay.model.CardModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CardRepository extends JpaRepository<CardModel, UUID> {
    List<CardModel> findByUserId(UUID userId);
    List<CardModel> findByUserIdAndStatus(UUID userId, String status);
}