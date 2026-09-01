package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface GatewayRepository extends JpaRepository<GatewayModel, UUID> {
    @Query("SELECT g FROM GatewayModel g WHERE LOWER(g.providerName) = :name")
    GatewayModel getGatewayProvider(@Param("name") String name);

    @Query("SELECT g FROM GatewayModel g WHERE LOWER(g.providerName) = LOWER(:name)")
    Optional<GatewayModel> findGatewayProviderIgnoreCase(@Param("name") String name);
}
