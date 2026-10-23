package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.MobileMoneyGatewayMappingsModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface MobileMoneyGatewayMappingsRepository extends JpaRepository<MobileMoneyGatewayMappingsModel, UUID> {

    Optional<MobileMoneyGatewayMappingsModel> findByProviderIdAndGateway(UUID providerId, String gateway);
}
