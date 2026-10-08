package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserCardsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface UserCardsRepository extends JpaRepository<UserCardsModel, UUID> {

    /**
     * Collection queries cannot be wrapped in Optional (Spring Data rejects them at
     * bootstrap), so an absent result is an empty list rather than an empty Optional.
     */
    List<UserCardsModel> findByUserId(@Param("userId") UUID userId);
}
