package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.PaymentChannelDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos.ResolveAccountResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.service.PaymentChannelsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Bank / mobile-money directory for the bank-transfer picker.
 * GET /api/payment-channels                -> banks/momo providers for a country
 * GET /api/payment-channels/resolve        -> verify an account number's name before sending
 */
@RestController
@RequestMapping("/api/payment-channels")
@RequiredArgsConstructor
public class PaymentChannelsController {

    private final PaymentChannelsService paymentChannelsService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<PaymentChannelDTO>>> list(
            @RequestParam String countryCode,
            @RequestParam(required = false) String type) {
        List<PaymentChannelDTO> channels = paymentChannelsService.listChannels(countryCode, type);
        return ResponseEntity.ok(ApiResponse.success(channels, "Payment channels retrieved"));
    }

    @GetMapping("/resolve")
    public ResponseEntity<ApiResponse<ResolveAccountResponseDTO>> resolve(
            @RequestParam String channelCode,
            @RequestParam String accountNumber) {
        ResolveAccountResponseDTO resolved = paymentChannelsService.resolveAccount(channelCode, accountNumber);
        return ResponseEntity.ok(ApiResponse.success(resolved, "Account resolved"));
    }
}
