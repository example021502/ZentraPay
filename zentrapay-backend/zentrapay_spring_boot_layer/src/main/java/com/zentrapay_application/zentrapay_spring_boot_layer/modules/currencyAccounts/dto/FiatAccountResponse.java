package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto;

public record AccountResponse(
        String accountId,
        String userId,
        String currencyCode,
        String currencyName,
        String accountType,
        Double balance,
        String status,
        String accountNumber,
        String bankName,
        String country,
        String network,
        String walletAddress,
        String createdAt
) {}