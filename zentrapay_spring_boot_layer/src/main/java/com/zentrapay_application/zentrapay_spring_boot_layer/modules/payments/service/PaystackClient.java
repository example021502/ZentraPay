package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.GatewayCreateCustomerDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaystackCustomerResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaystackInitializeResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaystackRecipientResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaystackTransferResponseDTO;
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

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Thin wrapper over the Paystack REST API (PRIMARY national gateway).
 * All monetary amounts cross this boundary in the gateway's subunit
 * (pesewas for GHS) — callers pass major units and we convert here.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class PaystackClient {

    private final RestTemplate restTemplate;

    @Value("${paystack.base-url}")
    private String baseUrl;
    @Value("${paystack.secret-key}")
    private String secretKey;
    @Value("${paystack.callback-url}")
    private String callbackUrl;

    // ------------------------------------------------------------------
    // Customer registration
    // ------------------------------------------------------------------

    public PaystackCustomerResponseDTO createCustomer(GatewayCreateCustomerDTO customer) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("email", customer.email());
        body.put("first_name", nullSafe(customer.firstName()));
        body.put("last_name", nullSafe(customer.lastName()));
        if (customer.phoneNumber() != null && !customer.phoneNumber().isBlank()) {
            body.put("phone", customer.phoneNumber());
        }
        PaystackCustomerResponseDTO response = post("/customer", body, PaystackCustomerResponseDTO.class);
        requireSuccess(response != null && response.status(), "customer registration",
                response == null ? null : response.message());
        return response;
    }

    // ------------------------------------------------------------------
    // Inbound checkout (transaction initialize)
    // ------------------------------------------------------------------

    public PaystackInitializeResponseDTO initializeTransaction(
            String email, BigDecimal amountMajor, String currency, String reference) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("email", email);
        body.put("amount", toSubunit(amountMajor));
        body.put("currency", currency);
        body.put("reference", reference);
        if (callbackUrl != null && !callbackUrl.isBlank()) {
            body.put("callback_url", callbackUrl);
        }
        PaystackInitializeResponseDTO response = post(
                "/transaction/initialize", body, PaystackInitializeResponseDTO.class);
        requireSuccess(response != null && response.status(), "transaction initialization",
                response == null ? null : response.message());
        return response;
    }

    // ------------------------------------------------------------------
    // Recipient registration (tier-2 token creation)
    // ------------------------------------------------------------------

    /**
     * @param type     "nuban" for bank accounts, "mobile_money" for wallets
     * @param bankCode bank/momo provider code (Paystack uses bank_code for both)
     */
    public PaystackRecipientResponseDTO createTransferRecipient(
            String type, String name, String accountNumber, String bankCode, String currency) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("type", type);
        body.put("name", name);
        body.put("account_number", accountNumber);
        body.put("bank_code", bankCode);
        body.put("currency", currency);
        PaystackRecipientResponseDTO response = post("/transferrecipient", body, PaystackRecipientResponseDTO.class);
        requireSuccess(response != null && response.status(), "recipient registration",
                response == null ? null : response.message());
        return response;
    }

    // ------------------------------------------------------------------
    // Outbound transfer
    // ------------------------------------------------------------------

    public PaystackTransferResponseDTO initiateTransfer(
            BigDecimal amountMajor, String recipientCode, String currency, String reason, String reference) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("source", "balance");
        body.put("amount", toSubunit(amountMajor));
        body.put("recipient", recipientCode);
        body.put("currency", currency);
        body.put("reference", reference);
        if (reason != null && !reason.isBlank()) {
            body.put("reason", reason);
        }
        PaystackTransferResponseDTO response = post("/transfer", body, PaystackTransferResponseDTO.class);
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
        headers.set("Authorization", "Bearer " + secretKey);
        try {
            ResponseEntity<T> response = restTemplate.exchange(
                    url, HttpMethod.POST, new HttpEntity<>(body, headers), responseType);
            return response.getBody();
        } catch (RestClientResponseException e) {
            log.error("Paystack {} failed [{}]: {}", path, e.getStatusCode(), e.getResponseBodyAsString());
            throw new PaymentGatewayException("Paystack request to " + path + " failed: " + e.getMessage(), e);
        } catch (Exception e) {
            log.error("Paystack {} unreachable: {}", path, e.getMessage());
            throw new PaymentGatewayException("Paystack is unreachable, please try again", e);
        }
    }

    private void requireSuccess(boolean ok, String action, String gatewayMessage) {
        if (!ok) {
            throw new PaymentGatewayException(
                    "Paystack " + action + " rejected: " + (gatewayMessage == null ? "unknown error" : gatewayMessage));
        }
    }

    /** Paystack expects subunits (pesewas/kobo) — 2-decimal currencies. */
    private long toSubunit(BigDecimal amountMajor) {
        return amountMajor.movePointRight(2).longValueExact();
    }

    private String nullSafe(String value) {
        return value == null ? "" : value;
    }
}