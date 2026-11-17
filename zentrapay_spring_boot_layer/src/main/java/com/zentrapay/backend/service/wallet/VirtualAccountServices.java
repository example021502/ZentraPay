package com.zentrapay.backend.service.wallet;

import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.service.common.Utils;
import com.zentrapay.backend.service.gateway.FincraServices;
import com.zentrapay.backend.service.user.UserProfileServices;
import com.zentrapay.backend.service.user.UsersService;
import lombok.extern.slf4j.Slf4j;
import com.zentrapay.backend.repository.*;
import com.zentrapay.backend.dto.wallet.*;
import com.zentrapay.backend.service.region.SupportedRegionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class VirtualAccountServices {

    private final VirtualAccountRepository accounts;
    private final CryptoAccountRepository cryptoAccountRepository;
    private final CryptoWalletRepository cryptoWalletRepository;
    private final SupportedRegionService supportedRegionService;
    private final FincraServices fincraServices;
    private final UsersService usersService;
    private final UserProfileServices userProfileServices;

    private final CurrenciesServices currenciesServices;


    // Fetches the authenticated user's fiat wallets (wallets table) and crypto
    // wallets (crypto_wallets table) in the exact shape the frontend expects.
    @Transactional(readOnly = true)
    public AccountsBalancesResponseDTO getUserBalances(UUID userId) {
        // Collects the fiat and crypto accounts with their balances for the home screen
        log.info("Loading account balances for user {}", userId);
        final List<VirtualAccountDTO> fiatAccounts = accounts.getAccountsByUserId(userId).stream()
                .map(v -> new VirtualAccountDTO(
                        v.getId(),
                        v.getMerchantReference(),
                        v.getCurrencyCode(),
                        v.getStatus(),
                        v.getAccountNumber(),
                        v.getAccountType(),
                        v.getBankName(),
                        v.getLabel(),
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
        log.info("==== CREATING THE USER WALLET ACCOUNT FOR : {} {}", req.currencyCode(), userId);

        // Only a currency some supported country uses as its default can be opened
        final String currencyCode = supportedRegionService.requireSupportedCurrency(req.currencyCode());
        UserModel user = usersService.getUser(userId);
        UserProfileModel p = userProfileServices.getUserProfile(userId);
        if (p.getIdentityDocumentNumber().isEmpty() || p.getIdDocumentFrontPath().isEmpty() || p.getIdDocumentBackPath().isEmpty()) {
            throw new RuntimeException("Critical profile information is missing. Upload you kyc documents to continue.");
        }
        String zentag = Utils.getZentag(currencyCode, user.getPhoneNumber());
        VirtualAccountModel account = fincraServices.createNewAccount(user.getUserId(), user.getEmail(), user.getFirstName(), user.getLastName(), currencyCode, p.getIdentityDocumentNumber(), p.getIdentityDocumentType(), "individual", zentag);

        return new VirtualAccountDTO(
                account.getId(),
                account.getMerchantReference(),
                account.getCurrencyCode(),
                account.getStatus(),
                account.getAccountNumber(),
                account.getAccountType(),
                account.getBankName(),
                account.getLabel(),
                account.getBalance(),
                account.isActive(),
                account.isDefault(),
                account.getCreatedAt()
        );
    }

    @Transactional(readOnly = true)
    public List<SupportedCurrencyDTO> getSupportedCurrencies(UUID userId) {
        List<String> codes = accounts.getCurrencyCodesByUserId(userId);
        return currenciesServices.getCurrencies(codes);
    }

    public boolean accountExists(UUID userId, String currencyCode) {
        return accounts.existsByUserIdAndCurrencyCode(userId, currencyCode);
    }

    public VirtualAccountModel checkBalance(UUID userId, String currencyCode, BigDecimal amount) {
        VirtualAccountModel a = getAccount(userId, currencyCode, null);
        if (a.getBalance().compareTo(amount) < 0) {
            throw new RuntimeException("Insufficiency funds.");
        }
        return a;
    }

    public VirtualAccountModel getAccount(UUID userId, String currencyCode, String merchantReference) {
        return accounts.getAccountByUserIdAndCurrencyCodeOrMerchantReference(userId, currencyCode, merchantReference)
                .orElseThrow(() -> new RuntimeException("Account not found."));
    }

}
