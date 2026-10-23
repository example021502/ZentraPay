package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.GatewayModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

/**
 * Data access for {@code gateway_providers} - one row per connected gateway
 * (PAYSTACK / FLUTTERWAVE / ONAFRIQ).
 */
public interface GatewayRepository extends JpaRepository<GatewayModel, UUID> {

    /** Finds a gateway by its name, ignoring case ("paystack" finds PAYSTACK). */
    Optional<GatewayModel> findByProviderNameIgnoreCase(String providerName);
}
