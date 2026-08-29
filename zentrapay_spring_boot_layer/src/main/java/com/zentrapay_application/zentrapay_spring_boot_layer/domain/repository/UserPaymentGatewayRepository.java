package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserPaymentGatewayModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserPaymentGatewayRepository extends JpaRepository<UserPaymentGatewayModel, UUID> {

    /** Local-first customer lookup: has this user already been registered at this gateway? */
    Optional<UserPaymentGatewayModel> findByUserIdAndGatewayName(UUID userId, String gatewayName);
}