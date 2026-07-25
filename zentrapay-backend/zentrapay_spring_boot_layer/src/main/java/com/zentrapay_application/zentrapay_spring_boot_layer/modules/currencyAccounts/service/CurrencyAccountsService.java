package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.CreateCryptoAccountRequest;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.CreateFiatAccountRequest;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.CryptoAccountResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.dto.FiatAccountResponse;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model.CryptoAccountModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model.FiatCurrencyAccountModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.repository.CryptoCurrencyAccountRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.repository.FiatCurrencyAccountRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.UserWalletsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.repository.UserWalletRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CurrencyAccountsService {
    private final FiatCurrencyAccountRepository fiatRepository;
    private final UserWalletRepository fiatWalletRepository;
    private final CryptoCurrencyAccountRepository cryptoRepository;

    public FiatAccountResponse createFiatAccount(CreateFiatAccountRequest request) {

        List<UserWalletsModel> wallet = fiatWalletRepository.findByUserId(request.userId());
        final UUID wallet_id = wallet.getFirst().getWalletId();
        // Check if account of same currency already exists
        if (!fiatRepository.findByWalletIdAndCurrencyCode(wallet_id, request.currency()).isEmpty()) {
            throw new RuntimeException("Account of same currency already exists");
        }

        FiatCurrencyAccountModel account = new FiatCurrencyAccountModel();
        account.setWalletId(wallet_id);
        account.setAccountName(request.accountName());
        account.setCurrencyCode(request.currency());
        account.setCountryIsoCode(request.isoCode());
        account.setBalance(0.0);
        account.setStatus("active");
        fiatRepository.save(account);
        return new FiatAccountResponse(account.getAccountName(), account.getCurrencyCode(), account.getCountryIsoCode(), account.getBalance(), account.getStatus(), account.getCreatedAt().toString());
    }

    public CryptoAccountResponse createCryptoAccount(CreateCryptoAccountRequest request) {
        // Create crypto_currency account
        CryptoAccountModel account = new CryptoAccountModel();
        account.setUserId(request.userId());
        account.setCurrencyCode(request.currencyCode());
        account.setCurrencyName(request.currencyName());
        account.setNetwork(request.network());
        account.setWalletAddress(request.walletAddress());
        account.setBalance(0.0);
        account.setStatus("ACTIVE");

        cryptoRepository.save(account);
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


}
