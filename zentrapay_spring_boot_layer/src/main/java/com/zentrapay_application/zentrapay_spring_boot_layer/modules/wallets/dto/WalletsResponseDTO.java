package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto;

import java.util.List;

public record WalletsResponseDTO(
        List<FiatWalletDTO> fiatWallets,
        List<CryptoWalletDTO> cryptoWallets
) {
}
