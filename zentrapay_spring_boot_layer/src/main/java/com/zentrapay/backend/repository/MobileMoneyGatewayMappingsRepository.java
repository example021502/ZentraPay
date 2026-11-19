package com.zentrapay.backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MobileMoneyGatewayMappingsRepository extends JpaRepository<MobileMoneyGatewayMappingsModel, UUID> {

    Optional<MobileMoneyGatewayMappingsModel> findByProviderIdAndGateway(UUID providerId, String gateway);

    List<MobileMoneyGatewayMappingsModel> findByProviderId(UUID providerId);

    List<MobileMoneyGatewayMappingsModel> findByGatewayIgnoreCaseAndCountryCodeIgnoreCase(String gateway, String countryCode);
}
