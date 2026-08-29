package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayCustomerModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * Data access for {@code gateway_customers} — ties one gateway customer ID
 * to one user per gateway (unique constraint user_id + gateway_name).
 */
public interface GatewayCustomerRepository extends JpaRepository<GatewayCustomerModel, Long> {

    Optional<GatewayCustomerModel> findByUserIdAndGatewayName(String userId, String gatewayName);
}
