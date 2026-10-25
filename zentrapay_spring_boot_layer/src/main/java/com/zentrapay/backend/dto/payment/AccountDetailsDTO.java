package com.zentrapay.backend.dto.payment;


import java.util.UUID;

public record AccountDetailsDTO(
    UUID accountId,
    UUID walletId,
    String accountName,
    String zentag,
    String currencyCode
) {}