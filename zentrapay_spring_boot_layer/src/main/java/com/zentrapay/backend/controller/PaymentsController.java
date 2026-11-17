package com.zentrapay.backend.controller;

import com.zentrapay.backend.dto.common.ApiResponse;
import com.zentrapay.backend.dto.payment.CheckoutResponseDTO;
import com.zentrapay.backend.dto.payment.GatewayCustomerDTO;
import com.zentrapay.backend.dto.payment.RetryDTOs;
import com.zentrapay.backend.dto.payment.TransactionRequest;
import com.zentrapay.backend.service.payment.TransactionRetryService;
import com.zentrapay.backend.dto.payment.VerifiedAccountDTO;
import com.zentrapay.backend.dto.payment.VerifyAccountRequestDTO;
import com.zentrapay.backend.dto.transaction.TransactionDTO;
import com.zentrapay.backend.security.AuthenticatedUser;
import com.zentrapay.backend.security.CurrentUser;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.QRCodeService;
import com.zentrapay.backend.service.payment.PaymentServices;
import com.zentrapay.backend.service.payment.WalletFundingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.UUID;

/**
 * Payments - money out of and into the wallet.
 *
 * <pre>
 * POST /api/payments/initialize             send money (P2P wallet-to-wallet or to a bank account)
 * POST /api/payments/verify-account         ask the providers who own a bank account / mobile-money wallet
 * GET  /api/payments/paystack/access-code   start a wallet top-up checkout
 * POST /api/payments/paystack/customer      get/create my customer on Paystack
 * POST /api/payments/flutterwave/customer   get/create my customer on Flutterwave
 * GET  /api/payments/{accountId}/QR code image for an account
 * </pre>
 * Webhooks live in their own controllers (Paystack / Flutterwave / Onafriq).
 */
@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentsController {

    private final PaymentServices paymentServices;
    private final WalletFundingService walletFundingService;
    private final QRCodeService qrCodeService;
    private final TransactionRetryService transactionRetryService;

    /**
     * Sends money. The signed-in user is the sender.
     */
    @PostMapping({"/initialize", "/pay"})
    public ResponseEntity<ApiResponse<TransactionDTO>> initialize(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody TransactionRequest request) {
        TransactionDTO transaction = paymentServices.initialize(user.getUserId(), request);
        return ResponseEntity.ok(ApiResponse.success(transaction, messageFor(transaction)));
    }

    /**
     * Retry, step 1: are the sender and the receiver of this failed payment still valid? (no PIN, nothing moves)
     */
    @PostMapping("/retry/{transactionId}/check")
    public ResponseEntity<ApiResponse<RetryDTOs.RetryCheckDTO>> checkRetry(
            @CurrentUser AuthenticatedUser user, @PathVariable UUID transactionId) {
        RetryDTOs.RetryCheckDTO check = transactionRetryService.check(user.getUserId(), transactionId);
        return ResponseEntity.ok(ApiResponse.success(check, check.message()));
    }

    /**
     * Retry, step 2: with the PIN, checks again and makes the payment again.
     */
    @PostMapping("/retry/{transactionId}")
    public ResponseEntity<ApiResponse<TransactionDTO>> retry(
            @CurrentUser AuthenticatedUser user, @PathVariable UUID transactionId,
            @Valid @RequestBody RetryDTOs.RetryRequest request) {
        TransactionDTO transaction = transactionRetryService.retry(user.getUserId(), transactionId, request.pin());
        return ResponseEntity.ok(ApiResponse.success(transaction, messageFor(transaction)));
    }

    /**
     * Asks the payment providers who own a bank account / mobile-money wallet (nothing is debited).
     */
    @PostMapping("/verify-account")
    public ResponseEntity<ApiResponse<VerifiedAccountDTO>> verifyAccount(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody VerifyAccountRequestDTO request) {
        return ResponseEntity.ok(ApiResponse.success(
                paymentServices.verifyAccount(user.getUserId(), request), "Account checked"));
    }

    /**
     * Starts a wallet top-up and returns what the app needs to open the checkout.
     */
    @GetMapping("/paystack/access-code")
    public ResponseEntity<ApiResponse<CheckoutResponseDTO>> accessCode(
            @CurrentUser AuthenticatedUser user,
            @RequestParam BigDecimal amount,
            @RequestParam String currencyCode) {
        CheckoutResponseDTO checkout = walletFundingService.startCheckout(user.getUserId(), amount, currencyCode);
        return ResponseEntity.ok(ApiResponse.success(checkout, "Checkout created"));
    }

    @PostMapping("/paystack/customer")
    public ResponseEntity<ApiResponse<GatewayCustomerDTO>> paystackCustomer(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(
                walletFundingService.customerOn(user.getUserId(), Datatypes.PaymentGateway.PAYSTACK), "Paystack customer ready"));
    }

    @PostMapping("/flutterwave/customer")
    public ResponseEntity<ApiResponse<GatewayCustomerDTO>> flutterwaveCustomer(@CurrentUser AuthenticatedUser user) {
        return ResponseEntity.ok(ApiResponse.success(
                walletFundingService.customerOn(user.getUserId(), Datatypes.PaymentGateway.FLUTTERWAVE), "Flutterwave customer ready"));
    }

    /**
     * QR code (PNG) for an account.
     */
    @GetMapping(value = "/{accountId}/qr", produces = MediaType.IMAGE_PNG_VALUE)
    public ResponseEntity<byte[]> getAccountQRCode(@PathVariable UUID accountId) {
        try {
            return ResponseEntity.ok(qrCodeService.generateQRCodeForAccount(accountId));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    // Message shown to the user: instant payments are done, bank payouts are still on their way
    private String messageFor(TransactionDTO transaction) {
        return transaction.status() == Datatypes.TransactionStatus.SUCCESS
                ? "Payment successful"
                : "Payment submitted. We will notify you once it is complete.";
    }
}
