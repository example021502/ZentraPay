package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.DisbursementRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.WalletToWalletRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.services.PaymentsServices;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * REST controller for all payment operations.
 * <p>
 * Mirrors the Node.js Express layer's {@code /api/payments} routes:
 * <ul>
 *   <li>{@code POST /api/payments/internal} — Wallet-to-wallet transfers between ZentraPay users</li>
 *   <li>{@code POST /api/payments/disbursement} — Outbound national & international disbursements via Paystack</li>
 * </ul>
 * <p>
 * All endpoints return a standardized {@link ApiResponse} envelope.
 */
@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentsController {

    private static final Logger log = LoggerFactory.getLogger(PaymentsController.class);

    private final PaymentsServices paymentsServices;

    /**
     * Internal wallet-to-wallet transfer between ZentraPay app users.
     * <p>
     * Mirrors the Node.js route: {@code POST /api/payments/internal}
     * <p>
     * Request body (matches Node.js payload):
     * <pre>
     * {
     *   "userId": "uuid",
     *   "PIN": "1234",
     *   "recipient": { "phoneNumber": "+234...", "zentag": "@johndoe" },
     *   "paymentDetails": { "amount": 5000, "currencyCode": "NGN" }
     * }
     * </pre>
     *
     * @param request The validated wallet-to-wallet request
     * @return Standardized API response with payment details
     */
    @PostMapping("/internal")
    public ResponseEntity<ApiResponse<PaymentsResponseDTO>> internalPayment(
            @RequestBody @Valid WalletToWalletRequestDTO request) {
        log.info("[SPRING_CTRL] Wallet-to-wallet transfer initiated by userId={}, amount={} {}",
                request.userId(), request.paymentDetails().amount(), request.paymentDetails().currencyCode());
        PaymentsResponseDTO paymentDetails = paymentsServices.makePaymentToAppUser(request);
        return ResponseEntity.ok(ApiResponse.success(paymentDetails, "Internal payment successful"));
    }

    /**
     * Outbound disbursement to external wallets, bank accounts, or mobile money.
     * <p>
     * Mirrors the Node.js route: {@code POST /api/payments/disbursement}
     * <p>
     * Supports both national and international payouts across Africa via Paystack.
     * <p>
     * Request body (matches Node.js payload):
     * <pre>
     * {
     *   "userId": "uuid",
     *   "pin": "1234",
     *   "recipient": {
     *     "accountName": "John Doe",
     *     "accountNumber": "0123456789",
     *     "bankCode": "058",
     *     "bankName": "GTBank",
     *     "countryCode": "NG",
     *     "email": "john@example.com"
     *   },
     *   "paymentDetails": {
     *     "amount": 10000,
     *     "sourceCurrency": "NGN",
     *     "destinationCurrency": "NGN",
     *     "isInternational": false,
     *     "destinationType": "NUBAN",
     *     "narration": "ZentraPay Payout",
     *     "reference": "DISB-XXXXXXXX"
     *   }
     * }
     * </pre>
     *
     * @param request The validated disbursement request
     * @return Standardized API response with payment details
     */
    @PostMapping("/disbursement")
    public ResponseEntity<ApiResponse<PaymentsResponseDTO>> disbursement(
            @RequestBody @Valid DisbursementRequestDTO request) {
        log.info("[SPRING_CTRL] Disbursement initiated by userId={}, amount={} {} -> {}",
                request.userId(),
                request.paymentDetails().amount(),
                request.paymentDetails().sourceCurrency(),
                request.paymentDetails().destinationCurrency() != null
                        ? request.paymentDetails().destinationCurrency()
                        : request.paymentDetails().sourceCurrency());
        PaymentsResponseDTO paymentDetails = paymentsServices.makeDisbursement(request);
        return ResponseEntity.ok(ApiResponse.success(paymentDetails, "Disbursement processed successfully"));
    }
}