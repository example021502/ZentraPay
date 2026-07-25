package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto;

public record FiatAccountResponse(
        String accountName,
        String currencyCode,
        String isoCode,
        Double balance,
        String status,
        String createdAt
) {}
