package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.controller;


import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.WalletToWalletRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.services.PaymentsServices;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;


@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentsController {
    private final PaymentsServices paymentsServices;

    // WALLET TO WALLET USERS PAYMENTS
    @PostMapping("/internal")
    public ResponseEntity<ApiResponse<PaymentsResponseDTO>> internalPayment(@RequestBody @Valid WalletToWalletRequestDTO request) {
        System.out.println("[SPRING_CTRL] wallet to wallet transactions hit by " + request);
        PaymentsResponseDTO paymentDetails = paymentsServices.makePaymentToAppUser(request);
        return ResponseEntity.ok(ApiResponse.success(paymentDetails, "Payment successful"));
    }

    // WALLET TO WALLET USERS PAYMENTS
    @PostMapping("/disbursement")
    public ResponseEntity<ApiResponse<PaymentsResponseDTO>> internalPayment(@RequestBody @Valid WalletToWalletRequestDTO request) {
        System.out.println("[SPRING_CTRL] wallet to wallet transactions hit by " + request);
        PaymentsResponseDTO paymentDetails = paymentsServices.makePaymentToAppUser(request);
        return ResponseEntity.ok(ApiResponse.success(paymentDetails, "Payment successful"));
    }
}