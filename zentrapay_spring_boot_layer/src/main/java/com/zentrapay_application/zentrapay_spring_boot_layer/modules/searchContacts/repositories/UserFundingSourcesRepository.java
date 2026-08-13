package com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.repositories;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.models.UserBillProvidersModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.UUID;

public interface UserBillProvidersRepository extends JpaRepository<UserBillProvidersModel, UUID> {
    @Query("SELECT p.providerId FROM BillProvidersModel WHERE p.userId =: userId")
    List<UUID> findByUserId(UUID userId);
}