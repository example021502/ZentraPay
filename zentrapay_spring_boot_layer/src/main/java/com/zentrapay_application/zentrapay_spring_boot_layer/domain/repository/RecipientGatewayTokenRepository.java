package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.RecipientGatewayTokenModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface RecipientGatewayTokenRepository extends JpaRepository<RecipientGatewayTokenModel, UUID> {

    /** Outbound-transfer prerequisite: token for this recipient at this gateway. */
    Optional<RecipientGatewayTokenModel> findByRecipientIdAndGatewayName(UUID recipientId, String gatewayName);
}