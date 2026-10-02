package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.CardsModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CardsRepository extends JpaRepository<CardsModel, UUID> {
    Optional<CardsModel> findByCardIdOrderByCreatedAtDesc(UUID cardId);
}
