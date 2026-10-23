package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.CardsModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CardsRepository extends JpaRepository<CardsModel, UUID> {
    Optional<CardsModel> findByCardIdOrderByCreatedAtDesc(UUID cardId);
    CardsModel findByCardId(UUID cardId);
}
