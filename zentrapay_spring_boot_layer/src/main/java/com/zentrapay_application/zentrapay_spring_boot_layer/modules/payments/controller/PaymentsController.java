package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.QRCodeService;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.InitializePaymentRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.InitializePaymentResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.TransactionDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service.PaymentsInitializeService;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service.PaymentsService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;
import java.util.UUID;

/**
 * Wallet-to-wallet payments — API_CONTRACT.md §5.
 * POST /api/payments -> pay a searched contact (pin, sender, recipient, destination)
 */
@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentsController {

    private final PaymentsService paymentsService;
    private final PaymentsInitializeService paymentsInitializeService;
    private final QRCodeService qrCodeService;

    /**
     * POST /api/payments/initialize — customer checkout (inbound wallet
     * funding). Provisions the caller at the primary gateway (local-first,
     * business rule 1), initializes the hosted checkout, and fails over to
     * Flutterwave when the primary is down.
     */
    @PostMapping("/initialize")
    public ResponseEntity<ApiResponse<InitializePaymentResponseDTO>> initialize(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody InitializePaymentRequestDTO request) {
        InitializePaymentResponseDTO checkout =
                paymentsInitializeService.initialize(user.getUserId(), request);
        return ResponseEntity.ok(
                ApiResponse.success(checkout, "Checkout session created"));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<Optional<TransactionDTO>>> pay(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody PaymentRequestDTO request) {
        Optional<TransactionDTO> transaction = Optional.of(paymentsService.sendMoney(user.getUserId(), request)
                .orElseThrow(() -> new ResourceNotFoundException("Something went wrong, try again")));
        return ResponseEntity.ok(ApiResponse.success(transaction, "Payment successful"));
    }

    /**
     * Accepts account/checkout ID, fetches details on backend, and returns PNG bytes.
     */
    @GetMapping(value = "/{accountId}/qr", produces = MediaType.IMAGE_PNG_VALUE)
    public ResponseEntity<byte[]> getAccountQRCode(@PathVariable UUID accountId) {
        try {
            // Generate QR PNG bytes based strictly on the path ID
            byte[] qrImageBytes = qrCodeService.generateQRCodeForAccount(accountId);
            return ResponseEntity.ok(qrImageBytes);
        } catch (IllegalArgumentException e) {
            // Return 404 if account ID does not exist
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        } catch (Exception e) {
            // Return 500 on internal server rendering errors
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}
