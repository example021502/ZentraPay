package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.GatewayCreateCustomerDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.OnAfriqCustomerResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.OnafriqTransferResponseDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientResponseException;
import org.springframework.web.client.RestTemplate;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Thin wrapper over the Onafriq partner API (PRIMARY international gateway).
 * <p>
 * NOTE: the partner credentials in application.properties are still
 * placeholders; endpoint paths mirror the financial-institutions probe used
 * by GatewayDirectorySyncService and MUST be confirmed against the live
 * partner documentation once the account is provisioned. Until then a
 * failure here is non-fatal: TransfersService fails over to Flutterwave.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class OnafriqClient {

    private final RestTemplate restTemplate;

    @Value("${onafriq.base-url}")
    private String baseUrl;
    @Value("${onafriq.secret-key}")
    private String secretKey;
    @Value("${onafriq.partner-id}")
    private String partnerId;

    // ------------------------------------------------------------------
    // Customer registration
    // ------------------------------------------------------------------

    public OnAfriqCustomerResponseDTO createCustomer(GatewayCreateCustomerDTO customer) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("partner_id", partnerId);
        body.put("email", customer.email());
        body.put("first_name", customer.firstName());
        body.put("last_name", customer.lastName());
        if (customer.phoneNumber() != null && !customer.phoneNumber().isBlank()) {
            body.put("phone", customer.phoneNumber());
        }
        OnAfriqCustomerResponseDTO response = post("/customers", body, OnAfriqCustomerResponseDTO.class);
        requireSuccess(response != null && response.status(), "customer registration",
                response == null ? null : response.message());
        return response;
    }

    // ------------------------------------------------------------------
    // Outbound transfer (international corridor)
    // ------------------------------------------------------------------

    public OnafriqTransferResponseDTO initiateTransfer(
            String destinationType,
            String providerCode,
            String accountIdentifier,
            String recipientName,
            java.math.BigDecimal amountMajor,
            String currency,
            String narration,
            String reference) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("partner_id", partnerId);
        body.put("reference", reference);
        body.put("amount", amountMajor);
        body.put("currency", currency);
        body.put("destination_type", destinationType);
        body.put("provider_code", providerCode);
        body.put("account_identifier", accountIdentifier);
        body.put("recipient_name", recipientName);
        if (narration != null && !narration.isBlank()) {
            body.put("narration", narration);
        }
        OnafriqTransferResponseDTO response = post("/transfers", body, OnafriqTransferResponseDTO.class);
        requireSuccess(response != null && response.status(), "transfer execution",
                response == null ? null : response.message());
        return response;
    }

    // ------------------------------------------------------------------
    // HTTP plumbing
    // ------------------------------------------------------------------

    private <T> T post(String path, Object body, Class<T> responseType) {
        String url = baseUrl + path;
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Accept", "application/json");
        headers.set("Authorization", "Bearer " + secretKey);
        try {
            ResponseEntity<T> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>(body, headers), responseType);
            return response.getBody();
        } catch (RestClientResponseException e) {
            log.error("Onafriq {} failed [{}]: {}", path, e.getStatusCode(), e.getResponseBodyAsString());
            throw new PaymentGatewayException("Onafriq request to " + path + " failed: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Onafriq {} unreachable: {}", path, e.getMessage());
            throw new PaymentGatewayException("Onafriq is unreachable, please try again", e);
        }
    }

    private void requireSuccess(boolean ok, String action, String gatewayMessage) {
        if (!ok) {
            throw new PaymentGatewayException(
                    "Onafriq " + action + " rejected: " + (gatewayMessage == null ? "unknown error" : gatewayMessage));
        }
    }
}