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
 * Paystack webhook - POST /api/payments/paystack/webhook (public, no login token).
 *
 * <p>Paystack signs the raw body with HMAC-SHA512 using our secret key and sends it in the
 * {@code x-paystack-signature} header. A request that does not match is rejected (401)
 * before anything is read, so nobody else can change a transaction's status.
 *
 * <p>Answers: 200 = handled (or nothing to do), 401 = bad signature, 400 = unreadable body,
 * 500 = we failed to process it, so Paystack will send it again.
 */
@Slf4j
@RestController
@RequestMapping("/api/payments/paystack")
@RequiredArgsConstructor
public class PaystackWebhookController {

    private final PaymentWebhookService webhookService;
    private final ObjectMapper objectMapper;

    @Value("${paystack.secret-key}")
    private String paystackSecretKey;

    @PostMapping(value = "/webhook", consumes = "application/json")
    public ResponseEntity<Void> webhook(@RequestBody String rawBody, HttpServletRequest request) {
        String signature = request.getHeader("x-paystack-signature");
        if (!WebhookSignature.hmacMatches("HmacSHA512", paystackSecretKey, rawBody, signature)) {
            log.warn("Paystack webhook signature mismatch - rejecting");
            return ResponseEntity.status(401).build();
        }

        JsonNode payload;
        try {
            payload = objectMapper.readTree(rawBody);
        } catch (Exception e) {
            log.warn("Paystack webhook body is not valid JSON: {}", e.getMessage());
            return ResponseEntity.badRequest().build();
        }

        try {
            webhookService.handlePaystackEvent(payload);
            return ResponseEntity.ok().build();
        } catch (Exception e) {
            log.error("Failed to process Paystack webhook - asking Paystack to retry: {}", e.getMessage(), e);
            return ResponseEntity.status(500).build();
        }
    }
}
