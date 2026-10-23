package com.zentrapay.backend.service.gateway;

import com.zentrapay.backend.dto.payment.GatewayTransferResult;
import com.zentrapay.backend.exception.PaymentGatewayException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import tools.jackson.databind.JsonNode;

import java.math.BigDecimal;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Onafriq API calls - the PRIMARY gateway for cross-border (international) payments.
 *
 * <p><b>NOTE:</b> the Onafriq partner account is not provisioned yet (placeholder
 * credentials in application.properties), so the endpoint paths and field names
 * below are best guesses. Confirm them against the partner documentation before
 * going live. Until then every call fails cleanly and the caller fails over to
 * Flutterwave (or refunds the sender).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class OnafriqServices {

    private static final String GATEWAY = "Onafriq";

    private final GatewayHttp http;

    @Value("${onafriq.base-url}")
    private String baseUrl;
    @Value("${onafriq.secret-key}")
    private String secretKey;
    @Value("${onafriq.partner-id}")
    private String partnerId;

    /** Registers the sender with Onafriq and returns its customer id. */
    public String createCustomer(String email, String firstName, String lastName, String phoneNumber) {
        log.info("Onafriq: creating customer for {}", email);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("partner_id", partnerId);
        body.put("email", email);
        body.put("first_name", firstName);
        body.put("last_name", lastName);
        if (phoneNumber != null && !phoneNumber.isBlank()) {
            body.put("phone", phoneNumber);
        }
        return idFrom(http.post(GATEWAY, baseUrl + "/customers", secretKey, body, JsonNode.class), "customer");
    }

    /** Registers the receiving bank account / mobile-money wallet and returns its recipient id. */
    public String createRecipient(String checkoutType, String countryCode, String accountName,
                                  String accountNumber, String channelCode, String currency) {
        log.info("Onafriq: creating {} recipient {} / {}", checkoutType, channelCode, accountNumber);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("partner_id", partnerId);
        body.put("destination_type", checkoutType);
        body.put("provider_code", channelCode);
        body.put("account_identifier", accountNumber);
        body.put("recipient_name", accountName);
        body.put("country_code", countryCode);
        body.put("currency", currency);
        return idFrom(http.post(GATEWAY, baseUrl + "/recipients", secretKey, body, JsonNode.class), "recipient");
    }

    /** Sends a cross-border payout. The reference is our idempotency key. */
    public GatewayTransferResult sendTransfer(BigDecimal amount, String recipientId, String currency,
                                              String narration, String reference) {
        log.info("Onafriq: transfer ref={} amount={} {} recipient={}", reference, amount, currency, recipientId);
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("partner_id", partnerId);
        body.put("reference", reference);
        body.put("amount", amount);
        body.put("currency", currency);
        body.put("recipient_id", recipientId);
        if (narration != null && !narration.isBlank()) {
            body.put("narration", narration);
        }

        JsonNode response = http.post(GATEWAY, baseUrl + "/transfers", secretKey, body, JsonNode.class);
        String status = response == null ? "" : response.path("data").path("status").asString("").toUpperCase();
        if ("FAILED".equals(status) || "REVERSED".equals(status)) {
            throw new PaymentGatewayException("Onafriq transfer not accepted (status " + status + ")");
        }
        return new GatewayTransferResult(idFrom(response, "transfer"), "SUCCESSFUL".equals(status) || "SUCCESS".equals(status));
    }

    // Reads data.id from the common {status, message, data} envelope, or fails with the gateway's message
    private String idFrom(JsonNode response, String what) {
        boolean ok = response != null && response.path("status").asBoolean(false);
        String id = response == null ? "" : response.path("data").path("id").asString("");
        if (!ok || id.isBlank()) {
            String reason = response == null ? "no response" : response.path("message").asString("unknown error");
            throw new PaymentGatewayException("Onafriq " + what + " request failed: " + reason);
        }
        return id;
    }
}
