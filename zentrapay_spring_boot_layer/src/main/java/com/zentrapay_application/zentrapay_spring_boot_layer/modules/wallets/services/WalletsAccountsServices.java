package com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.services;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.CryptoAccountModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.CryptoWalletModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatAccountModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatWalletModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dtos.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class WalletsAccountsServices {

    private final FiatAccountRepository fiatAccountRepository;
    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final CryptoAccountRepository cryptoAccountRepository;
    private final CryptoWalletRepository cryptoWalletRepository;
    private final SupportedCurrenciesRepository supportedCurrenciesRepository;
    private final CurrencyRepository currencyRepository;

    // Fetches the authenticated user's fiat wallets (wallets table) and crypto
    // wallets (crypto_wallets table) in the exact shape the frontend expects.
    @Transactional(readOnly = true)
    public AccountsBalancesResponseDTO getUserBalances(UUID userId) {
        final FiatWalletModel wallet = fiatWalletRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Something went wrong. Wallet missing!"));

        List<FiatAccountDTO> fiatAccounts = fiatAccountRepository.findByWalletId(wallet.getWalletId()).stream()
                .map(account -> new FiatAccountDTO(
                        account.getAccountId(),
                        account.getAccountName(),
                        account.getCurrencyCode(),
                        account.getZentag(),
                        account.getBalance(),
                        account.isDefault(),
                        account.getStatus(),
                        account.getCreatedAt()
                ))
                .toList();

        final CryptoWalletModel crypto_wallet = cryptoWalletRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Something went wrong. Wallet missing!"));
        List<CryptoAccountDTO> cryptoAccounts = cryptoAccountRepository.findByWalletId(crypto_wallet.getWalletId()).stream()
                .map(account -> new CryptoAccountDTO(
                        account.getCryptoAccountId(),
                        account.getCurrencyCode(),
                        account.getNetwork(),
                        account.getWalletAddress(),
                        account.getIsDefault(),
                        account.getBalance().toPlainString(),
                        account.getStatus(),
                        account.getCreatedAt()
                ))
                .toList();
        return new AccountsBalancesResponseDTO(fiatAccounts, cryptoAccounts);
    }

    @Transactional
    public FiatAccountDTO createFiatAccount(UUID userId, CreateFiatAccountRequest req) {

        final FiatWalletModel wallet = fiatWalletRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Something went wrong. Wallet missing!"));

        if (fiatAccountRepository.existsByWalletIdAndCurrencyCode(wallet.getWalletId(), req.currencyCode())) {
            throw new IllegalArgumentException("Account for that currency already exist!");
        }

        final UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Something went wrong. User missing!"));

        FiatAccountModel account = new FiatAccountModel();
        account.setWalletId(wallet.getWalletId());
        account.setAccountName(req.accountName());
        account.setCurrencyCode(req.currencyCode());
        // Comment: same zentag shape as the default account minted at registration
        // (UsersService.register) — one unique zentag per currency account, not
        // per user, so a sender can pay into a specific currency of a recipient's
        // wallet. Naturally unique: phone number is unique per user and a wallet
        // can only ever hold one account per currency (checked just above).
        account.setZentag(user.getPhoneNumber() + "_" + req.currencyCode() + "@zentrapay");
        account.setBalance(BigDecimal.ZERO);
        account.setDefault(false);
        account.setStatus("active");
        fiatAccountRepository.save(account);

        return new FiatAccountDTO(
                account.getAccountId(),
                account.getAccountName(),
                account.getCurrencyCode(),
                account.getZentag(),
                account.getBalance(),
                account.isDefault(),
                account.getStatus(),
                account.getCreatedAt()
                );
    }

    @Transactional(readOnly = true)
    public List<SupportedCurrencyDTO> getSupportedCurrencies(UUID userId) {

        final FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(userId);
        final List<String> userCurrencyAccountsCurrencies = fiatAccountRepository.getAccountsCurrenciesByWalletId(wallet.getWalletId());
        final List<String> currencyCodes = supportedCurrenciesRepository.getCurrencyCodes(userCurrencyAccountsCurrencies);
        System.out.println("THE CURRENCY CODE FETCHED IS:: " + userCurrencyAccountsCurrencies);
        return currencyRepository.getCurrenciesByCurrencyCodes(currencyCodes).stream()
                .map(currency -> new SupportedCurrencyDTO(
                        currency.getCurrencyCode(),
                        currency.getCurrencyName(),
                        currency.getDecimalPlaces()
                ))
                .toList();
    }

}
