package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.dto;

/**
 * DTO representing the data returned upon successful authentication.
 * We use a Java record here for immutability and conciseness.
 */
public record WalletBalancesResponseDTO(
        List balances,
        String fullName,
        String email,
        String zentag
) {}
