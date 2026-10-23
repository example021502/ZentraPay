package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.GatewayCustomerModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

/**
 * Data access for {@code gateway_customers} - one gateway-side customer per (user, gateway).
 */
public interface GatewayCustomerRepository extends JpaRepository<GatewayCustomerModel, Integer> {

    /** The customer this gateway already issued to this user, if any. */
    Optional<GatewayCustomerModel> findByUserIdAndGatewayId(UUID userId, UUID gatewayId);
}
