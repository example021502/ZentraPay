package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayCustomerModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayRecipientsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.Optional;
import java.util.UUID;

/**
 * Data access for {@code gateway_recipients} — one gateway recipient code
 * per (user, gateway, account, provider) tuple.
 */
public interface GatewayCustomerReposittory extends JpaRepository<GatewayCustomerModel, Long> {
    @Query("SELECT r FROM GatewayRecipientsModel r  WHERE r.userId = :userId AND r.gatewayId = :gatewayId")
    Optional<GatewayCustomerModel> getByUserIdAndGatewayId(UUID userId, UUID gatewayId);
}
