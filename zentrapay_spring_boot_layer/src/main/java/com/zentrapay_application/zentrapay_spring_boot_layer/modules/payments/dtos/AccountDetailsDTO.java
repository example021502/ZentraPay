package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.dtos;


import java.util.UUID;

public record AccountDetailsDTO(
    UUID accountId,
    UUID walletId,
    String accountName,
    String zentag,
    String currencyCode
) {}