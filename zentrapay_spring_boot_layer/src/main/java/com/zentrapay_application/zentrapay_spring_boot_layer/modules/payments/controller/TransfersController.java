package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.TransferExecuteRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.TransferExecuteResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service.TransfersService;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.AuthenticatedUser;
import com.zentrapay_application.zentrapay_spring_boot_layer.security.CurrentUser;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Outbound payouts to bank accounts (BANK/nuban) and mobile money wallets
 * (MOBILE_MONEY) — POST /api/transfers/execute.
 * <p>
 * Gateway routing is corridor-based: the sender's registration country vs.
 * the recipient's country picks the primary gateway (national -> Paystack,
 * international -> Onafriq), and Flutterwave is the universal failover.
 * Recipient registration at the gateway is lazy per the two-tier token
 * architecture (business rule 3) — an existing
 * {@code recipient_gateway_tokens} row means the transfer executes directly.
 */
@RestController
@RequestMapping("/api/transfers")
@RequiredArgsConstructor
public class TransfersController {

    private final TransfersService transfersService;

    @PostMapping("/execute")
    public ResponseEntity<ApiResponse<TransferExecuteResponseDTO>> execute(
            @CurrentUser AuthenticatedUser user,
            @Valid @RequestBody TransferExecuteRequestDTO request) {
        TransferExecuteResponseDTO transfer =
                transfersService.execute(user.getUserId(), request);
        return ResponseEntity.ok(
                ApiResponse.success(transfer, "Transfer submitted"));
    }
}