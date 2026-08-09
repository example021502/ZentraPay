package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Currency;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Wallet;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.CryptoWalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.CurrencyRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.WalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto.CreateFiatWalletRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto.CryptoWalletDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto.FiatWalletDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dto.WalletsResponseDTO;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

/**
 * API contract §3 — replaces the deleted {@code currencyAccounts} +
 * {@code walletBalances} modules with one {@code /api/wallets} surface backed
 * by the canonical {@link Wallet}/{@code CryptoWallet} entities.
 */
@Service
@RequiredArgsConstructor
@Transactional
public class WalletsService {

    private static final Logger log = LoggerFactory.getLogger(WalletsService.class);

    private final WalletRepository walletRepository;
    private final CryptoWalletRepository cryptoWalletRepository;
    private final CurrencyRepository currencyRepository;

    @Transactional(readOnly = true)
    public WalletsResponseDTO getUserWallets(UUID userId) {
        var fiat = walletRepository.findByUserId(userId).stream().map(FiatWalletDTO::from).toList();
        var crypto = cryptoWalletRepository.findByUserId(userId).stream().map(CryptoWalletDTO::from).toList();
        return new WalletsResponseDTO(fiat, crypto);
    }

    @Transactional(readOnly = true)
    public List<Currency> getAllSupportedCurrencies() {
        return currencyRepository.findByIsActiveTrue();
    }

    public FiatWalletDTO createFiatWallet(UUID userId, CreateFiatWalletRequestDTO request) {
        if ((walletRepository.findByUserIdAndCurrencyCode(userId, request.currencyCode())).isPresent()) {
            throw new RuntimeException("A wallet named '" + request.walletName() + "'of currency code '" + request.currencyCode() + "Already exists");
        }

        Wallet wallet = new Wallet();
        wallet.setUserId(userId);
        wallet.setWalletName(request.walletName());
        wallet.setCurrencyCode(request.currencyCode());
        wallet.setCountryCode(request.countryCode());
        wallet.setStatus("ACTIVE");
        // First wallet for a user (defensively — registration already creates a
        // default one) becomes the default so the app always has one to fall back on.
        wallet.setDefault(walletRepository.findByUserId(userId).isEmpty());

        wallet = walletRepository.save(wallet);
        log.info("[WALLETS] Fiat wallet created: walletId={}, userId={}, currency={}", wallet.getWalletId(), userId, request.currencyCode());
        return FiatWalletDTO.from(wallet);
    }


}
