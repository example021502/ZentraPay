package com.zentrapay.backend.service.DigitalAccounts;

import com.zentrapay.backend.dto.wallet.*;
import com.zentrapay.backend.entity.*;
import com.zentrapay.backend.exception.ResourceNotFoundException;
import com.zentrapay.backend.repository.AccountsRepository;
import com.zentrapay.backend.service.common.Datatypes;
import com.zentrapay.backend.service.common.Utils;
import com.zentrapay.backend.service.user.UsersService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AccountsServices {

    private final CryptoAccountsServices cryptoAccountsServices;
    private final UsersService usersService;
    private final AccountsRepository accounts;

    private final CurrenciesServices currenciesServices;

    @Transactional(readOnly = true)
    public void checkAccount(UUID userId, String currencyCode) {
        if (!accounts.existsByUserIdAndCurrencyCode(userId, currencyCode)) {
            throw new RuntimeException("Account not found.");
        }
    }

    @Transactional(readOnly = true)
    public BigDecimal getBalance(UUID userId, String currencyCode) {
        return accounts.getBalanceByUserIdAndCurrencyCode(userId, currencyCode);
    }

    @Transactional
    public BigDecimal debit(BigDecimal amount, String currencyCode, UUID userId) {

        AccountsModel account = accounts.findByUserIdAndCurrencyCodeForUpdate(userId, currencyCode).orElseThrow(() -> new RuntimeException("Account not found."));
        if (account.getBalance().compareTo(amount) < 0) {
            throw new RuntimeException("Insufficiency funds.");
        }

        BigDecimal newBalance = account.getBalance().subtract(amount);
        account.setBalance(newBalance);
        accounts.save(account);
        return newBalance;
    }

    @Transactional
    public BigDecimal credit(BigDecimal amount, String currencyCode, UUID userId) {
        AccountsModel account = accounts.findByUserIdAndCurrencyCodeForUpdate(userId, currencyCode).orElseThrow(() -> new RuntimeException("Account not found."));
        BigDecimal newBalance = account.getBalance().add(amount);
        account.setBalance(newBalance);
        accounts.save(account);
        return newBalance;
    }


    @Transactional
    public FiatDigitalAccountDTO createFiatAccount(
            UUID userId,
            CreateFiatAccountRequest req
    ) {
        // Opens a new currency account in the user's wallet (one account per currency)
        log.info("==== CREATING THE USER ACCOUNT... ====");
        UserModel user = usersService.getUser(userId);
        AccountsModel account = new AccountsModel();
        account.setUserId(userId);
        account.setLabel(req.accountName());
        account.setEmail(user.getEmail());
        account.setCurrencyCode(req.currencyCode());
        account.setZentag(Utils.getZentag(req.currencyCode(), user.getPhoneNumber()));
        account.setPhoneNumber(user.getPhoneNumber());
        account = accounts.save(account);
        return new FiatDigitalAccountDTO(
                account.getId(),
                account.getZentag(),
                account.getCurrencyCode(),
                account.getStatus(),
                account.getPhoneNumber(),
                account.getLabel(),
                account.getBalance(),
                account.getActive(),
                account.isDefault(),
                account.getCreatedAt()
        );
    }

    @Transactional
    public void createDefaultFiatAccount(
            String label,
            UUID userId,
            String email,
            String currencyCode,
            String zentag,
            String phoneNumber
    ) {
        // Opens a new currency account in the user's wallet (one account per currency)
        log.info("==== CREATING THE USER DEFAULT ACCOUNT... ====");
        AccountsModel account = new AccountsModel();
        account.setUserId(userId);
        account.setLabel(label);
        account.setEmail(email);
        account.setCurrencyCode(currencyCode);
        account.setZentag(zentag);
        account.setPhoneNumber(phoneNumber);
        accounts.save(account);
    }

    @Transactional(readOnly = true)
    public List<SupportedCurrencyDTO> getSupportedCurrencies(UUID userId) {
        List<String> codes = accounts.getCurrencyCodesByUserId(userId);
        return currenciesServices.getCurrencies(codes);
    }

    public boolean accountExists(UUID userId, String currencyCode) {
        return accounts.existsByUserIdAndCurrencyCode(userId, currencyCode);
    }

    @Transactional(readOnly = true)
    public void requireActiveDigitalAccount(UUID userId, String currencyCode) {
        AccountsModel a = getAccount(userId, currencyCode, null);
        if (!Datatypes.AccountStatus.ACTIVE.equals(a.getActive())) {
            throw new RuntimeException("You account is currently " + a.getActive() + ". Please contact customer support to resolve this issue.");
        }
    }

    public AccountsModel checkBalance(UUID userId, String currencyCode, BigDecimal amount) {
        AccountsModel a = getAccount(userId, currencyCode, null);
        if (a.getBalance().compareTo(amount) < 0) {
            throw new RuntimeException("Insufficiency funds.");
        }
        return a;
    }

    public AccountsModel getAccount(UUID userId, String currencyCode, String merchantReference) {
        return accounts.getAccountByUserIdAndCurrencyCodeOrMerchantReference(userId, currencyCode, merchantReference)
                .orElseThrow(() -> new RuntimeException("Account not found."));
    }

    public AccountsModel getAccount(UUID accountId) {
        return accounts.findById(accountId)
                .orElseThrow(() -> new RuntimeException("Account not found."));
    }


    public AccountsBalancesResponseDTO getAccounts(UUID userId) {
        List<FiatDigitalAccountDTO> fiatAccounts = accounts.getAccountsByUserId(userId).stream()
                .map(a -> new FiatDigitalAccountDTO(
                        a.getId(),
                        a.getZentag(),
                        a.getCurrencyCode(),
                        a.getStatus(),
                        a.getPhoneNumber(),
                        a.getLabel(),
                        a.getBalance(),
                        a.getActive(),
                        a.isDefault(),
                        a.getCreatedAt()
                )).toList();

        List<CryptoAccountDTO> cryptoAccounts = cryptoAccountsServices.getAccount(userId).stream()
                .map(c -> new CryptoAccountDTO(
                        c.getId(),
                        c.getCurrencyCode(),
                        c.getNetwork(),
                        c.getAddress(),
                        c.getBalance(),
                        c.getIsDefault(),
                        c.getStatus(),
                        c.getCreatedAt()
                )).toList();

        return new AccountsBalancesResponseDTO(
                fiatAccounts,
                cryptoAccounts
        );
    }

    public String getZentag(UUID userId, String currencyCode) {
        return accounts.getMerchantReferenceByUserId(userId, currencyCode);
    }

    @Transactional
    public AccountsModel getAndLockAccountForUpdate(UUID userId, String currencyCode) {
        return accounts.findByUserIdAndCurrencyCodeForUpdate(userId, currencyCode)
                .orElseThrow(() -> new ResourceNotFoundException("Account not found."));

    }

    @Transactional
    public AccountsModel getAndLockAccountForUpdate(UUID accountId) {
        return accounts.findByIdForUpdate(accountId)
                .orElseThrow(() -> new ResourceNotFoundException("Account not found."));

    }

    @Transactional
    public UUID getOrCreateSystemClearingAccount(Datatypes.AccountTypes type, String currencyCode) {
        return accounts.getAccountByTypeAndCurrencyCodeForUpdate(type, currencyCode)
                .orElseGet(() -> {
                    AccountsModel a = new AccountsModel();
                    a.setCurrencyCode(currencyCode);
                    a.setAccountType(Datatypes.AccountTypes.CLEARING);
                    return accounts.save(a);
                }).getId();
    }

    @Transactional
    public UUID getOrCreateSystemFloatAccount(Datatypes.Gateway gateway, String currencyCode) {
        return accounts.gatAccountByLabelIgnoreCaseAndCurrencyCodeIgnoreCaseForUpdate(gateway.toString(), currencyCode)
                .orElseGet(() -> {
                    AccountsModel a = new AccountsModel();
                    a.setCurrencyCode(currencyCode);
                    a.setLabel(gateway.toString());
                    return accounts.save(a);
                }).getId();
    }


}
