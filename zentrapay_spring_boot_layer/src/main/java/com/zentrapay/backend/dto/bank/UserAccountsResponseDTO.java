package com.zentrapay.backend.dto.bank;

import java.util.List;

/**
 * Top-level payload returned by GET /api/zbanking/userAccounts — the user's
 * linked bank accounts with display info, balances and the primary marker.
 *
 * Mirrors the Flutter {@code BankAccountsSnapshot} shape: the ZBank header
 * reads {@code primary} and the horizontal strip renders {@code accounts}.
 */
public record UserAccountsResponseDTO(
    UserAccountsDTO primary,
    List<UserAccountsDTO> accounts
) {
}