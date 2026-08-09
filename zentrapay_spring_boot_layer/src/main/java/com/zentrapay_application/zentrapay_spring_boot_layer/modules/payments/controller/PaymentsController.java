package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.ExternalPaymentRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.InternalPaymentRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaystackAccessCodeResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.services.PaymentsServices;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.transactions.dto.TransactionResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;

/**
 * API contract §6 — {@code /api/payments}.
 * <p>
 * Standardized payload structure for all payment endpoints:
 * {@code {pin, recipientDetails, amountDetails}} — userId is extracted
 * from the JWT token via {@code @CurrentUser}.
 */
@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentsController {

    private static final Logger log = LoggerFactory.getLogger(PaymentsController.class);

    private final PaymentsServices paymentsServices;

    // ========================================================================
    // INTERNAL WALLET-TO-WALLET TRANSFER
    // ========================================================================
    @PostMapping("/internal")
    public ResponseEntity<ApiResponse<TransactionResponseDTO>> internalPayment(
            @CurrentUser AuthenticatedUser user,
            @RequestBody @Valid InternalPaymentRequestDTO request) {
        log.info("[PAYMENTS_CTRL] Internal transfer initiated by userId={}, amountDetails={}, recipientDetails={}",
                user.userId(), request.amountDetails(), request.recipientDetails());
        TransactionResponseDTO transaction = paymentsServices.makeInternalPayment(user.userId(), request);
        return ResponseEntity.ok(ApiResponse.success(transaction, "Internal payment successful"));
    }

    // ========================================================================
    // EXTERNAL PAYMENT ENDPOINTS (recipientDetails, amountDetails, pin)
    // ========================================================================

    /**
     * Bank transfer using standardized payload structure.
     * POST /api/payments/bank-transfer
     */
    @PostMapping("/bank-transfer")
    public ResponseEntity<ApiResponse<TransactionResponseDTO>> bankTransfer(
            @CurrentUser AuthenticatedUser user,
            @RequestBody @Valid ExternalPaymentRequestDTO request) {
        log.info("[PAYMENTS_CTRL] Bank transfer initiated by userId={}, amount={} {} -> channel={}",
                user.userId(), request.amountDetails().amount(), request.amountDetails().currencyCode(),
                request.recipientDetails().channelCode());
        // Set providerType to BANK for this endpoint
        ExternalPaymentRequestDTO bankRequest = new ExternalPaymentRequestDTO(
                request.pin(), request.recipientDetails(), request.amountDetails(), "BANK");
        TransactionResponseDTO transaction = paymentsServices.makeBankTransfer(user.userId(), bankRequest);
        return ResponseEntity.ok(ApiResponse.success(transaction, "Bank transfer processed"));
    }

    /**
     * Mobile money transfer using standardized payload structure.
     * POST /api/payments/mobile-money
     */
    @PostMapping("/mobile-money")
    public ResponseEntity<ApiResponse<TransactionResponseDTO>> mobileMoneyTransfer(
            @CurrentUser AuthenticatedUser user,
            @RequestBody @Valid ExternalPaymentRequestDTO request) {
        log.info("[PAYMENTS_CTRL] Mobile money transfer initiated by userId={}, amount={} {} -> channel={}",
                user.userId(), request.amountDetails().amount(), request.amountDetails().currencyCode(),
                request.recipientDetails().channelCode());
        // Set providerType to MOBILE_MONEY for this endpoint
        ExternalPaymentRequestDTO mmRequest = new ExternalPaymentRequestDTO(
                request.pin(), request.recipientDetails(), request.amountDetails(), "MOBILE_MONEY");
        TransactionResponseDTO transaction = paymentsServices.makeMobileMoneyTransfer(user.userId(), mmRequest);
        return ResponseEntity.ok(ApiResponse.success(transaction, "Mobile money transfer processed"));
    }

    // ========================================================================
    // PAYSTACK COLLECTION (wallet funding)
    // ========================================================================
    @GetMapping("/paystack/access-code")
    public ResponseEntity<ApiResponse<PaystackAccessCodeResponseDTO>> paystackAccessCode(
            @CurrentUser AuthenticatedUser user,
            @RequestParam BigDecimal amount,
            @RequestParam String currencyCode) {
        PaystackAccessCodeResponseDTO response = paymentsServices.getPaystackAccessCode(user.userId(), amount, currencyCode);
        return ResponseEntity.ok(ApiResponse.success(response, "Paystack access code issued"));
    }

    /**
     * Public — Paystack calls this directly, so there is no {@code @CurrentUser}.
     * Authenticity is instead established by verifying {@code x-paystack-signature}
     * (see {@link PaymentsServices#handlePaystackWebhook}). The raw body is bound
     * as a {@code String} (not a parsed DTO) because HMAC verification must run
     * over the exact bytes Paystack signed.
     */
    @PostMapping("/paystack/webhook")
    public ResponseEntity<ApiResponse<Void>> paystackWebhook(
            @RequestBody String rawBody,
            @RequestHeader(value = "x-paystack-signature", required = false) String signature) {
        paymentsServices.handlePaystackWebhook(rawBody, signature);
        return ResponseEntity.ok(ApiResponse.success(null, "Webhook processed"));
    }
}