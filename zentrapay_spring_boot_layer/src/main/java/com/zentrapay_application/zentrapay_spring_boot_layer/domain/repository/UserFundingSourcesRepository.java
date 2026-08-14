package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.repositories;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserFundingSourceModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.UUID;

public interface UserFundingSourcesRepository extends JpaRepository<UserFundingSourceModel, UUID> {
    @Query("SELECT f.sourceId FROM UserFundingSourcesModelSearch f WHERE f.userId =: userId")
    List<UUID> getFundingSourcesIdsByUserId(UUID userId);
}