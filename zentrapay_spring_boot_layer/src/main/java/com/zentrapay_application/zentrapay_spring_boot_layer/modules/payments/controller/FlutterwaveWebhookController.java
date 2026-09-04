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

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

/**
 * Flutterwave webhook — POST /api/payments/flutterwave/webhook (public,
 * permitted in {@link com.zentrapay_application.zentrapay_spring_boot_layer.security.SecurityConfig}).
 * <p>
 * Unlike Paystack, Flutterwave doesn't HMAC-sign the body — it echoes back
 * whatever secret hash was configured on the dashboard (here,
 * {@code flutterwave.webhook-secret}) in the {@code verif-hash} header. A
 * request whose header doesn't match that stored value is rejected outright.
 */
@Slf4j
@RestController
@RequestMapping("/api/payments/flutterwave")
@RequiredArgsConstructor
public class FlutterwaveWebhookController {

    private final PaymentWebhookService webhookService;
    private final ObjectMapper objectMapper;

    @Value("${flutterwave.webhook-secret}")
    private String flutterwaveWebhookSecret;

    @PostMapping(value = "/webhook", consumes = "application/json")
    public ResponseEntity<Void> webhook(
            @RequestBody String rawBody,
            HttpServletRequest request) {

        String verifHash = request.getHeader("verif-hash");
        if (verifHash == null || !MessageDigest.isEqual(
                verifHash.getBytes(StandardCharsets.UTF_8),
                flutterwaveWebhookSecret.getBytes(StandardCharsets.UTF_8))) {
            log.warn("Flutterwave webhook verif-hash mismatch — rejecting");
            return ResponseEntity.status(401).build();
        }

        try {
            JsonNode payload = objectMapper.readTree(rawBody);
            webhookService.handleFlutterwaveEvent(payload);
        } catch (Exception e) {
            // Comment: Never 500 a webhook — log and acknowledge, same
            // reasoning as the Paystack handler.
            log.error("Failed to process Flutterwave webhook: {}", e.getMessage(), e);
        }

        return ResponseEntity.ok().build();
    }
}
