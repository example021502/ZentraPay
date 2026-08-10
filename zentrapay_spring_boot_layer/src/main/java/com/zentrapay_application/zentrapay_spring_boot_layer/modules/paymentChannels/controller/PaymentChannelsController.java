package com.zentrapay_application.zentrapay_spring_boot_layer.modules.paymentChannels.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.paymentChannels.dto.PaymentChannelDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.paymentChannels.dto.ResolveAccountResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.paymentChannels.service.PaymentChannelsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Payment channel directory (bank/mobile-money) — API_CONTRACT.md §7.
 */
@RestController
@RequestMapping("/api/payment-channels")
@RequiredArgsConstructor
public class PaymentChannelsController {

    private final PaymentChannelsService paymentChannelsService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<PaymentChannelDTO>>> listChannels(
            @RequestParam(required = false) String countryCode,
            @RequestParam(required = false) String type) {
        return ResponseEntity.ok(ApiResponse.success(
                paymentChannelsService.listChannels(countryCode, type), "Payment channels retrieved"));
    }

    @GetMapping("/resolve")
    public ResponseEntity<ApiResponse<ResolveAccountResponseDTO>> resolveAccount(
            @RequestParam String channelCode,
            @RequestParam String accountNumber) {
        return ResponseEntity.ok(ApiResponse.success(
                paymentChannelsService.resolveAccount(channelCode, accountNumber), "Account resolved"));
    }
}
