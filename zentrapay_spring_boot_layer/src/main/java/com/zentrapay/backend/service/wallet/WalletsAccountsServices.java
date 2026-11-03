package com.zentrapay.backend.service.wallet;

import com.zentrapay.backend.entity.*;
import lombok.extern.slf4j.Slf4j;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.dto.wallet.*;
import com.zentrapay.backend.service.region.CurrencyCatalog;
import com.zentrapay.backend.service.region.SupportedRegionService;
import lombok.RequiredArgsConstructor;
import org.jspecify.annotations.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class WalletsAccountsServices {

    private final FiatAccountRepository fiatAccountRepository;
    private final UserRepository userRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final CryptoAccountRepository cryptoAccountRepository;
    private final CryptoWalletRepository cryptoWalletRepository;
    private final SupportedRegionService supportedRegionService;

    // Fetches the authenticated user's fiat wallets (wallets table) and crypto
    // wallets (crypto_wallets table) in the exact shape the frontend expects.
    @Transactional(readOnly = true)
    public AccountsBalancesResponseDTO getUserBalances(UUID userId) {
        // Collects the fiat and crypto accounts with their balances for the home screen
        log.info("Loading wallet balances for user {}", userId);
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
        // Opens a new currency account in the user's wallet (one account per currency)
        log.info("Creating a {} account for user {}", req.currencyCode(), userId);

        // Only a currency some supported country uses as its default can be opened
        final String currencyCode = supportedRegionService.requireSupportedCurrency(req.currencyCode());

        final FiatWalletModel wallet = fiatWalletRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Something went wrong. Wallet missing!"));

        if (fiatAccountRepository.existsByWalletIdAndCurrencyCode(wallet.getWalletId(), currencyCode)) {
            throw new IllegalArgumentException("Account for that currency already exist!");
        }

        final UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Something went wrong. User missing!"));

        FiatAccountModel account = createAccount(req, currencyCode, wallet, user);
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

    private static @NonNull FiatAccountModel createAccount(CreateFiatAccountRequest req, String currencyCode, FiatWalletModel wallet, UserModel user) {
        FiatAccountModel account = new FiatAccountModel();
        account.setWalletId(wallet.getWalletId());
        account.setAccountName(req.accountName());
        account.setCurrencyCode(currencyCode);
        // Comment: same zentag shape as the default account minted at registration
        // (UsersService.register) — one unique zentag per currency account, not
        // per user, so a sender can pay into a specific currency of a recipient's
        // wallet. Naturally unique: phone number is unique per user and a wallet
        // can only ever hold one account per currency (checked just above).
        account.setZentag(user.getPhoneNumber() + "_" + currencyCode + "@zentrapay");
        account.setBalance(BigDecimal.ZERO);
        account.setDefault(false);
        account.setStatus("ACTIVE");
        return account;
    }

    @Transactional(readOnly = true)
    public List<SupportedCurrencyDTO> getSupportedCurrencies(UUID userId) {

        final FiatWalletModel wallet = fiatWalletRepository.getWalletByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Something went wrong. Wallet missing!"));

        // Currencies come from the countries' default_currency; offer the ones the user has no account in yet
        final java.util.Set<String> held = fiatAccountRepository.getAccountsCurrenciesByWalletId(wallet.getWalletId()).stream()
                .map(code -> code.trim().toUpperCase())
                .collect(java.util.stream.Collectors.toSet());
        return supportedRegionService.supportedCurrencyCodes().stream()
                .filter(code -> !held.contains(code))
                .map(code -> new SupportedCurrencyDTO(code, CurrencyCatalog.name(code), CurrencyCatalog.decimals(code)))
                .toList();
    }

}
