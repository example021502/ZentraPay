package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayRecipientsModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * Data access for {@code gateway_recipients} — one gateway recipient code
 * per (user, gateway, account, provider) tuple.
 */
public interface GatewayRecipientsRepository extends JpaRepository<GatewayRecipientsModel, Long> {

    Optional<GatewayRecipientsModel> findByUserIdAndGatewayNameAndAccountIdentifierAndProviderCode(
            String userId, String gatewayName, String accountIdentifier, String providerCode);

    List<GatewayRecipientsModel> findByUserId(String userId);
}
