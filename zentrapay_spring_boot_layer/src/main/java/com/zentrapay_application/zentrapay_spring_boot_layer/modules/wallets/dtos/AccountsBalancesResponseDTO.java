package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dtos;

import java.util.List;

/**
 * Top-level payload returned by GET /api/wallets - matches the frontend
 * WalletsSnapshot / API_CONTRACT.md se3: {fiatWallets:[...], cryptoWallets:[...]}.
 */
public record AccountsBalancesResponseDTO(
        List<FiatAccountDTO> fiatBalances,
        List<CryptoAccountDTO> cryptoBalances
) {
}