package com.zentrapay.backend.controller;

import com.zentrapay.backend.service.common.WebhookSignature;
import com.zentrapay.backend.service.payment.PaymentWebhookService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * Flutterwave webhook - POST /api/payments/flutterwave/webhook (public, no login token).
 *
 * <p>Flutterwave does not sign the body; it sends back the "secret hash" typed into its
 * dashboard in the {@code verif-hash} header. It must equal {@code flutterwave.webhook-secret}.
 * Answers are the same as the Paystack webhook (200 / 401 / 400 / 500).
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
    public ResponseEntity<Void> webhook(@RequestBody String rawBody, HttpServletRequest request) {
        if (!WebhookSignature.sameText(flutterwaveWebhookSecret, request.getHeader("verif-hash"))) {
            log.warn("Flutterwave webhook verif-hash mismatch - rejecting");
            return ResponseEntity.status(401).build();
        }

        JsonNode payload;
        try {
            payload = objectMapper.readTree(rawBody);
        } catch (Exception e) {
            log.warn("Flutterwave webhook body is not valid JSON: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        }

        try {
            webhookService.handleFlutterwaveEvent(payload);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Failed to process Flutterwave webhook - asking Flutterwave to retry: {}", e.getMessage(), e);
            return ResponseEntity.status(500).build();
        }
    }
}
