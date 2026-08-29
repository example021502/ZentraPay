package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayCustomerModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.GatewayCustomerRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.GatewayCreateCustomerDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

/**
 * Multi-gateway customer architecture (business rule 1):
 * gateway customer IDs are NEVER stored on the users entity. Before any
 * customer-facing gateway call we check the {@code gateway_customers} table
 * locally for this (user, gateway) pair; only when absent do we hit the
 * gateway's /customer endpoint, persist the returned ID, and proceed.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GatewayCustomerService {

    public static final String GATEWAY_PAYSTACK = "PAYSTACK";
    public static final String GATEWAY_ONAFRIQ = "ONAFRIQ";
    public static final String GATEWAY_FLUTTERWAVE = "FLUTTERWAVE";

    private final GatewayCustomerRepository gatewayCustomerRepository;
    private final PaystackClient paystackClient;
    private final OnafriqClient onafriqClient;
    private final FlutterwaveClient flutterwaveClient;

    /**
     * Local-first gateway customer resolution. Returns the stored
     * {@code gateway_customer_id}, registering the user at the gateway
     * (and caching the result) only on first contact.
     */
    @Transactional(propagation = Propagation.REQUIRED)
    public String getOrCreateGatewayCustomer(UserModel user, String gatewayName) {
        String gateway = normalizeGateway(gatewayName);
        String userId = user.getUserId().toString();

        // 1. Local cache check — never re-register an existing customer.
        Optional<GatewayCustomerModel> existing =
                gatewayCustomerRepository.findByUserIdAndGatewayName(userId, gateway);
        if (existing.isPresent() && !existing.get().getGatewayCustomerId().isBlank()) {
            return existing.get().getGatewayCustomerId();
        }

        // 2. Register at the gateway.
        String customerId = registerAtGateway(user, gateway);

        // 3. Persist (insert or refresh the stale row).
        GatewayCustomerModel record = existing.orElseGet(GatewayCustomerModel::new);
        record.setUserId(userId);
        record.setGatewayName(gateway);
        record.setGatewayCustomerId(customerId);
        gatewayCustomerRepository.save(record);
        log.info("Registered user {} as customer {} at gateway {}", userId, customerId, gateway);
        return customerId;
    }

    private String registerAtGateway(UserModel user, String gateway) {
        GatewayCreateCustomerDTO payload = new GatewayCreateCustomerDTO(
                user.getEmail(), user.getFirstName(), user.getLastName(), user.getPhoneNumber());
        try {
            return switch (gateway) {
                case GATEWAY_PAYSTACK -> paystackClient.createCustomer(payload)
                        .data().customerCode();
                case GATEWAY_ONAFRIQ -> onafriqClient.createCustomer(payload)
                        .data().customerCode();
                case GATEWAY_FLUTTERWAVE -> {
                    var flw = flutterwaveClient.createCustomer(
                            user.getEmail(),
                            user.getFirstName() + " " + user.getLastName(),
                            user.getPhoneNumber());
                    yield String.valueOf(flw.data().id());
                }
                default -> throw new IllegalArgumentException("Unsupported gateway: " + gateway);
            };
        } catch (PaymentGatewayException e) {
            // A customer-creation failure must not register a blank token —
            // surface it so the caller can fail over to another gateway.
            throw e;
        }
    }

    public static String normalizeGateway(String gatewayName) {
        if (gatewayName == null || gatewayName.isBlank()) {
            throw new IllegalArgumentException("Gateway name is required");
        }
        return gatewayName.trim().toUpperCase();
    }
}