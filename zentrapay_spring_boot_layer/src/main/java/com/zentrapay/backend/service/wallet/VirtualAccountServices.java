package com.zentrapay.backend.service.wallet;

import com.zentrapay.backend.dto.gateway.FincraNewAccountResponse;
import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.service.common.Utils;
import com.zentrapay.backend.service.gateway.FincraServices;
import com.zentrapay.backend.service.user.UserProfileServices;
import com.zentrapay.backend.service.user.UsersService;
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
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class VirtualAccountServices {

    private final UserRepository userRepository;
    private final VirtualAccountRepository accounts;
    private final CryptoAccountRepository cryptoAccountRepository;
    private final CryptoWalletRepository cryptoWalletRepository;
    private final SupportedRegionService supportedRegionService;
    private final FincraServices fincraServices;
    private final UsersService usersService;
    private final UserProfileServices userProfileServices;

    // Fetches the authenticated user's fiat wallets (wallets table) and crypto
    // wallets (crypto_wallets table) in the exact shape the frontend expects.
    @Transactional(readOnly = true)
    public AccountsBalancesResponseDTO getUserBalances(UUID userId) {
        // Collects the fiat and crypto accounts with their balances for the home screen
        log.info("Loading account balances for user {}", userId);
        final List<VirtualAccountDTO> fiatAccounts = accounts.getAccountByUserId(userId).stream()
                .map(v -> new VirtualAccountDTO(
                        v.getId(),
                        v.getMerchantReference(),
                        v.getCurrency(),
                        v.getStatus(),
                        v.getAccountNumber(),
                        v.getAccountType(),
                        v.getBalance(),
                        v.isActive(),
                        v.isDefault(),
                        v.getCreatedAt()
                )).toList();

        final CryptoWalletModel crypto_wallet = cryptoWalletRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Something went wrong. Wallet missing!"));
        List<CryptoAccountDTO> cryptoAccounts = cryptoAccountRepository.findByWalletId(crypto_wallet.getWalletId()).stream()
                .map(c -> new CryptoAccountDTO(
                        c.getCryptoAccountId(),
                        c.getCurrencyCode(),
                        c.getNetwork(),
                        c.getWalletAddress(),
                        c.getIsDefault(),
                        c.getBalance().toPlainString(),
                        c.getStatus(),
                        c.getCreatedAt()
                ))
                .toList();
        return new AccountsBalancesResponseDTO(fiatAccounts, cryptoAccounts);
    }

    @Transactional
    public VirtualAccountDTO createFiatAccount(UUID userId, CreateFiatAccountRequest req) {
        // Opens a new currency account in the user's wallet (one account per currency)
        log.info("Creating a {} account for user {}", req.currencyCode(), userId);

        // Only a currency some supported country uses as its default can be opened
        final String currencyCode = supportedRegionService.requireSupportedCurrency(req.currencyCode());
        UserModel user = usersService.getUser(userId);
        UserProfileModel p = userProfileServices.getUserProfile(userId);
        if (p.getIdentityDocumentNumber().isEmpty() || p.getIdDocumentFrontPath().isEmpty() || p.getIdDocumentBackPath().isEmpty()) {
            throw new RuntimeException("Critical profile information is missing. Upload you kyc documents to continue.");
        }
        String zentag = Utils.getZentag(currencyCode, user.getPhoneNumber());
        FincraNewAccountResponse account = fincraServices.createNewAccount(user.getUserId(), user.getEmail(), user.getFirstName(), user.getLastName(), currencyCode, p.getIdentityDocumentNumber(), p.getIdentityDocumentType(), "individual", zentag);

        final FiatWalletModel wallet = fiatWalletRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("Something went wrong. Wallet missing!"));

        if (fiatAccountRepository.existsByWalletIdAndCurrencyCode(wallet.getWalletId(), currencyCode)) {
            throw new IllegalArgumentException("Account for that currency already exist!");
        }

        final UserModel user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("Something went wrong. User missing!"));

        FiatAccountModel account = createAccount(req, currencyCode, wallet, user);
        fiatAccountRepository.save(account);

        return new VirtualAccountDTO(
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
