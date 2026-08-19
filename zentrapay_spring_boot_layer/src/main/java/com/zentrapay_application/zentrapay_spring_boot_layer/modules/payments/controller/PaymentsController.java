package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.TransactionDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service.PaymentsService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Optional;

/**
 * Wallet-to-wallet payments — API_CONTRACT.md §5.
 * POST /api/payments -> pay a searched contact (pin, sender, recipient, destination)
 */
@RestController
@RequestMapping("/api/payments")
@RequiredArgsConstructor
public class PaymentsController {

    private final PaymentsService paymentsService;

    @PostMapping
    public ResponseEntity<ApiResponse<Optional<TransactionDTO>>> pay(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody PaymentRequestDTO request) {
        Optional<TransactionDTO> transaction = Optional.of(paymentsService.sendMoney(user.getUserId(), request)
                .orElseThrow(() -> new ResourceNotFoundException("Something went wrong, try again")));
        return ResponseEntity.ok(ApiResponse.success(transaction, "Payment successful"));
    }
}
