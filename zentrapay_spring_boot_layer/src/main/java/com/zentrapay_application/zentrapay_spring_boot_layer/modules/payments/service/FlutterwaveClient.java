package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.FlutterwaveCustomerResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.FlutterwavePaymentResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.FlutterwaveResolveResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.FlutterwaveTransferResponseDTO;
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
 * Thin wrapper over the Flutterwave v3 REST API (FAILOVER gateway for both
 * the national and international corridors). Unlike Paystack, Flutterwave
 * transfers take destination details inline — no pre-registration round
 * trip — so this client has no transferrecipient equivalent.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class FlutterwaveClient {

    private final RestTemplate restTemplate;

    @Value("${flutterwave.base-url}")
    private String baseUrl;
    @Value("${flutterwave.secret-key}")
    private String secretKey;

    // ------------------------------------------------------------------
    // Customer registration
    // ------------------------------------------------------------------

    public FlutterwaveCustomerResponseDTO createCustomer(
            String email, String fullName, String phoneNumber) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("email", email);
        if (fullName != null && !fullName.isBlank()) {
            body.put("name", fullName);
        }
        if (phoneNumber != null && !phoneNumber.isBlank()) {
            body.put("phonenumber", phoneNumber);
        }
        FlutterwaveCustomerResponseDTO response = post("/customers", body, FlutterwaveCustomerResponseDTO.class);
        requireSuccess(response != null && "success".equalsIgnoreCase(response.status()),
                "customer registration", response == null ? null : response.message());
        return response;
    }

    // ------------------------------------------------------------------
    // Inbound checkout (hosted payment link)
    // ------------------------------------------------------------------

    public FlutterwavePaymentResponseDTO initializePayment(
            String email, String fullName, String phoneNumber,
            java.math.BigDecimal amountMajor, String currency, String reference, String redirectUrl) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("tx_ref", reference);
        body.put("amount", amountMajor);
        body.put("currency", currency);
        if (redirectUrl != null && !redirectUrl.isBlank()) {
            body.put("redirect_url", redirectUrl);
        }
        Map<String, Object> customer = new LinkedHashMap<>();
        customer.put("email", email);
        if (fullName != null && !fullName.isBlank()) {
            customer.put("name", fullName);
        }
        if (phoneNumber != null && !phoneNumber.isBlank()) {
            customer.put("phonenumber", phoneNumber);
        }
        body.put("customer", customer);
        FlutterwavePaymentResponseDTO response = post("/payments", body, FlutterwavePaymentResponseDTO.class);
        requireSuccess(response != null && "success".equalsIgnoreCase(response.status()),
                "payment initialization", response == null ? null : response.message());
        return response;
    }

    // ------------------------------------------------------------------
    // Outbound transfer (failover payout)
    // ------------------------------------------------------------------

    /**
     * @param destinationType BANK or MOBILE_MONEY (normalized uppercase)
     * @param providerCode    bank code, or momo network code for MOBILE_MONEY
     */
    public FlutterwaveTransferResponseDTO initiateTransfer(
            String destinationType,
            String providerCode,
            String accountIdentifier,
            String recipientName,
            java.math.BigDecimal amountMajor,
            String currency,
            String narration,
            String reference) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("amount", amountMajor);
        body.put("currency", currency);
        body.put("reference", reference);
        if (narration != null && !narration.isBlank()) {
            body.put("narration", narration);
        }
        if ("MOBILE_MONEY".equalsIgnoreCase(destinationType)) {
            body.put("network", providerCode);
            body.put("mobile_number", accountIdentifier);
        } else {
            body.put("account_bank", providerCode);
            body.put("account_number", accountIdentifier);
        }
        body.put("beneficiary_name", recipientName);
        FlutterwaveTransferResponseDTO response = post("/transfers", body, FlutterwaveTransferResponseDTO.class);
        requireSuccess(response != null && "success".equalsIgnoreCase(response.status()),
                "transfer execution", response == null ? null : response.message());
        return response;
    }

    // ------------------------------------------------------------------
    // Account resolution (used by the bank-transfer UI to show the real
    // account holder's name before the user confirms a send)
    // ------------------------------------------------------------------

    public FlutterwaveResolveResponseDTO resolveAccount(String accountNumber, String bankCode) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("account_number", accountNumber);
        body.put("account_bank", bankCode);
        return post("/accounts/resolve", body, FlutterwaveResolveResponseDTO.class);
    }

    // ------------------------------------------------------------------
    // HTTP plumbing
    // ------------------------------------------------------------------

    private <T> T post(String path, Object body, Class<T> responseType) {
        String url = baseUrl + path;
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("Authorization", "Bearer " + secretKey);
        try {
            ResponseEntity<T> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>(body, headers), responseType);
            return response.getBody();
        } catch (RestClientResponseException e) {
            log.error("Flutterwave {} failed [{}]: {}", path, e.getStatusCode(), e.getResponseBodyAsString());
            throw new PaymentGatewayException("Flutterwave request to " + path + " failed: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Flutterwave {} unreachable: {}", path, e.getMessage());
            throw new PaymentGatewayException("Flutterwave is unreachable, please try again", e);
        }
    }

    private void requireSuccess(boolean ok, String action, String gatewayMessage) {
        if (!ok) {
            throw new PaymentGatewayException(
                    "Flutterwave " + action + " rejected: " + (gatewayMessage == null ? "unknown error" : gatewayMessage));
        }
    }
}