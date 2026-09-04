package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.controller;

import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service.PaymentWebhookService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * Paystack webhook — POST /api/payments/paystack/webhook (public, permitted
 * in {@link com.zentrapay_application.zentrapay_spring_boot_layer.security.SecurityConfig}).
 * <p>
 * Paystack signs every webhook body with HMAC-SHA512 keyed on the account's
 * secret key, sent in the {@code x-paystack-signature} header (hex-encoded).
 * A request that doesn't match is rejected before any parsing/DB work — an
 * unauthenticated caller must never be able to flip a transaction's status.
 */
@Slf4j
@RestController
@RequestMapping("/api/payments/paystack")
@RequiredArgsConstructor
public class PaystackWebhookController {

    private static final String HMAC_ALGO = "HmacSHA512";

    private final PaymentWebhookService webhookService;
    private final ObjectMapper objectMapper;

    @Value("${paystack.secret-key}")
    private String paystackSecretKey;

    @PostMapping(value = "/webhook", consumes = "application/json")
    public ResponseEntity<Void> webhook(
            @RequestBody String rawBody,
            HttpServletRequest request) {

        String signature = request.getHeader("x-paystack-signature");
        String expected = computeHmacSha512(rawBody);
        if (signature == null || !MessageDigest.isEqual(
                signature.toLowerCase().getBytes(StandardCharsets.UTF_8),
                expected.getBytes(StandardCharsets.UTF_8))) {
            log.warn("Paystack webhook signature mismatch — rejecting");
            return ResponseEntity.status(401).build();
        }

        try {
            JsonNode payload = objectMapper.readTree(rawBody);
            webhookService.handlePaystackEvent(payload);
        } catch (Exception e) {
            // Comment: Never 500 a webhook — log and acknowledge so Paystack
            // doesn't hammer this endpoint with retries for a parse error we
            // already know is on our side to fix.
            log.error("Failed to process Paystack webhook: {}", e.getMessage(), e);
        }

        return ResponseEntity.ok().build();
    }

    private String computeHmacSha512(String body) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGO);
            mac.init(new SecretKeySpec(paystackSecretKey.getBytes(StandardCharsets.UTF_8), HMAC_ALGO));
            byte[] digest = mac.doFinal(body.getBytes(StandardCharsets.UTF_8));
            StringBuilder hex = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                hex.append(String.format("%02x", b));
            }
            return hex.toString();
        } catch (Exception e) {
            log.error("Failed to compute Paystack webhook signature: {}", e.getMessage());
            return "";
        }
    }
}
