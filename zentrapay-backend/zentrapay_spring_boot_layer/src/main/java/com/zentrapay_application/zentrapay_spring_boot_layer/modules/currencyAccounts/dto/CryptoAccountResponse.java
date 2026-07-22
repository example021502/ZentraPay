package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto;

public record CryptoAccountResponse(
        String currencyCode,
        String currencyName,
        String network,
        String walletAddress,
        Double balance,
        String status,
        String createdAt
) {}