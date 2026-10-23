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
 * Onafriq webhook - POST /api/payments/onafriq/webhook (public, no login token).
 *
 * <p>ASSUMPTION: Onafriq signs the raw body with HMAC-SHA256 using {@code onafriq.webhook-secret}
 * and sends it in {@code x-onafriq-signature}. The partner account is not provisioned yet, so
 * confirm the header name and algorithm in the Onafriq documentation. Until a secret is
 * configured every request is rejected.
 */
@Slf4j
@RestController
@RequestMapping("/api/payments/onafriq")
@RequiredArgsConstructor
public class OnafriqWebhookController {

    private final PaymentWebhookService webhookService;
    private final ObjectMapper objectMapper;

    @Value("${onafriq.webhook-secret:}")
    private String onafriqWebhookSecret;

    @PostMapping(value = "/webhook", consumes = "application/json")
    public ResponseEntity<Void> webhook(@RequestBody String rawBody, HttpServletRequest request) {
        String signature = request.getHeader("x-onafriq-signature");
        if (!WebhookSignature.hmacMatches("HmacSHA256", onafriqWebhookSecret, rawBody, signature)) {
            log.warn("Onafriq webhook signature mismatch - rejecting");
            return ResponseEntity.status(401).build();
        }

        JsonNode payload;
        try {
            payload = objectMapper.readTree(rawBody);
        } catch (Exception e) {
            log.warn("Onafriq webhook body is not valid JSON: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        }

        try {
            webhookService.handleOnafriqEvent(payload);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Failed to process Onafriq webhook - asking Onafriq to retry: {}", e.getMessage(), e);
            return ResponseEntity.status(500).build();
        }
    }
}
