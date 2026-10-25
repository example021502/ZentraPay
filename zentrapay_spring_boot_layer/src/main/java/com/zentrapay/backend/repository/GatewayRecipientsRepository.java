package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.GatewayRecipientsModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

/**
 * Data access for {@code gateway_recipients} - payout destinations registered on a gateway.
 */
public interface GatewayRecipientsRepository extends JpaRepository<GatewayRecipientsModel, Long> {

    /** The recipient already registered on this gateway for exactly this destination, if any. */
    Optional<GatewayRecipientsModel> findByUserIdAndGatewayIdAndCheckoutTypeAndChannelCodeAndAccountIdentifier(
            UUID userId, UUID gatewayId, String checkoutType, String channelCode, String accountIdentifier);
}
