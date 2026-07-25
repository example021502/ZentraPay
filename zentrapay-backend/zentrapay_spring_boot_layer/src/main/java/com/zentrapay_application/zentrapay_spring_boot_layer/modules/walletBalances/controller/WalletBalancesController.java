package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.controller;

import com.zentrapay_application.zentrapay_spring_boot_layer.common.ApiResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto.RequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto.ResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.service.BalancesServices;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/currencyBalances")
@RequiredArgsConstructor
public class WalletBalancesController {
    private final BalancesServices balancesServices;

    @GetMapping("/fiatBalances/{userId}")
    public ResponseEntity<ApiResponse<ResponseDTO>> getFiatCurrencyBalances(@PathVariable("userId") String userId) {
        RequestDTO request = new RequestDTO(userId);
        System.out.println("[SPRING_CTRL] fiat balances hit by " + request);
        ResponseDTO userData = balancesServices.getFiatCurrencyBalances(request);
        return ResponseEntity.ok(ApiResponse.success(userData, "Fiat Balances Fetched Successfully"));
    }

    @GetMapping("/cryptoBalances/{userId}")
    public ResponseEntity<ApiResponse<ResponseDTO>> getCryptoCurrencyBalances(@PathVariable("userId") String userId) {
        RequestDTO request = new RequestDTO(userId);
        System.out.println("[SPRING_CTRL] crypto balances hit by " + request);
        ResponseDTO cryptoBalances = balancesServices.getCryptoCurrencyBalances(request);
        return ResponseEntity.ok(ApiResponse.success(cryptoBalances, "Crypto Balances Fetched Successfully"));
    }

    @GetMapping("/all/{userId}")
    public ResponseEntity<ApiResponse<ResponseDTO>> getAllCurrencyBalances(@PathVariable("userId") String userId) {
        RequestDTO request = new RequestDTO(userId);
        System.out.println("[SPRING_CTRL] getBalances hit by " + request);
        ResponseDTO allBalances = balancesServices.getAllCurrencyBalances(request);
        return ResponseEntity.ok(ApiResponse.success(allBalances, "Data fetch successful!"));
    }
}