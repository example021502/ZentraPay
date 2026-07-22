package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.CryptoAccountResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.CreateCryptoAccountRequest;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.CreateFiatAccountRequest;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.FiatAccountResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model.CryptoAccountModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model.CryptoWallet;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model.FiatAccountModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model.FiatWallet;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.repository.CryptoCurrencyAccountRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.repository.CryptoWalletRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.repository.FiatCurrencyAccountRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.repository.FiatWalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Service
@RequiredArgsConstructor
public class CurrencyAccountsService {
    private final FiatCurrencyAccountRepository fiatRepository;
    private final CryptoCurrencyAccountRepository cryptoRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final CryptoWalletRepository cryptoWalletRepository;

    public FiatAccountResponse createFiatAccount(CreateFiatAccountRequest request) {
        // Check if account of same currency already exists
        if (!fiatRepository.findByUserIdAndCurrencyCode(request.userId(), request.currency()).isEmpty()) {
            throw new RuntimeException("Account of same currency already exists");
        }

        FiatAccountModel account = new FiatAccountModel();
        account.setUserId(request.userId());
        account.setCurrencyCode(request.currency());
        account.setIsoCode(request.isoCode());
        account.setAccountName(request.accountName());
        account.setBalance(0.0);

        FiatAccountModel saved = fiatRepository.save(account);
        return mapToResponse(saved);
    }

    public CryptoAccountResponse createCryptoAccount(CreateCryptoAccountRequest request) {
        // Create crypto currency account
        CryptoAccountModel account = new CryptoAccountModel();
        account.setUserId(request.userId());
        account.setCurrencyCode(request.currencyCode());
        account.setCurrencyName(request.currencyName());
        account.setNetwork(request.network());
        account.setWalletAddress(request.walletAddress());
        account.setBalance(0.0);
        account.setStatus("ACTIVE");

        CryptoAccountModel saved = cryptoRepository.save(account);
        return mapToResponse(saved);
    }

    private FiatAccountResponse mapToResponse(FiatAccountModel account) {
        return new FiatAccountResponse(
                account.getAccountName(),
                account.getCurrencyCode(),
                account.getIsoCode(),
                account.getBalance(),
                account.getCreatedAt().toString()
        );
    }

    private CryptoAccountResponse mapToResponse(CryptoAccountModel account) {
        return new CryptoAccountResponse(
                account.getCurrencyCode(),
                account.getCurrencyName(),
                account.getNetwork(),
                account.getWalletAddress(),
                account.getBalance(),
                account.getStatus(),
                account.getCreatedAt().toString()
        );
    }

    public void createDefaultWallets(String userId, String countryIsoCode) {
        // Create default fiat wallet if not exists
        if (!fiatWalletRepository.existsByUserId(userId)) {
            FiatWallet fiatWallet = new FiatWallet();
            fiatWallet.setUserId(userId);
            fiatWallet.setWalletName("default_fiat_wallet");
            fiatWallet.setCountryIsoCode(countryIsoCode);
            fiatWallet.setTotalBalance(0.0);
            fiatWallet.setStatus("ACTIVE");
            fiatWalletRepository.save(fiatWallet);
        }

        // Create default crypto wallet if not exists
        if (!cryptoWalletRepository.existsByUserId(userId)) {
            CryptoWallet cryptoWallet = new CryptoWallet();
            cryptoWallet.setUserId(userId);
            cryptoWallet.setWalletName("default_crypto_wallet");
            cryptoWallet.setTotalBalance(0.0);
            cryptoWallet.setStatus("ACTIVE");
            cryptoWalletRepository.save(cryptoWallet);
        }
    }
}