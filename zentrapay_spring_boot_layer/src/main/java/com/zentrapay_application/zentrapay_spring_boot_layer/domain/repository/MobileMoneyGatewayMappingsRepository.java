package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.MobileMoneyGatewayMappingsModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface MobileMoneyGatewayMappingsRepository extends JpaRepository<MobileMoneyGatewayMappingsModel, UUID> {

    Optional<MobileMoneyGatewayMappingsModel> findByProviderIdAndGateway(UUID providerId, String gateway);
}
