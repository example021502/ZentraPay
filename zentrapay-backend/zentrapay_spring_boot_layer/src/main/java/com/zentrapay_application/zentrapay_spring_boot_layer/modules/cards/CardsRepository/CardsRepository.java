package com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.CardsRepository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.cards.models.CardsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface CardsRepository extends JpaRepository<CardsModel, UUID> {
    @Query("SELECT c FROM CardsModel c WHERE c.userId = :userId ORDER BY c.createdAt DESC")
    List<CardsModel> getByUserId(@Param("userId") UUID userId);
}