package com.zentrapay.backend.service.DigitalAccounts;

import com.zentrapay.backend.entity.CryptoAccountModel;
import com.zentrapay.backend.repository.CryptoAccountRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class CryptoAccountsServices {

    private final CryptoAccountRepository cryptoAccounts;

    // Fetches the authenticated user's fiat wallets (wallets table) and crypto
    // wallets (crypto_wallets table) in the exact shape the frontend expects.
    @Transactional(readOnly = true)
    public List<CryptoAccountModel> getAccount(UUID userId) {
        return cryptoAccounts.getAccountsByUserId(userId);

    }


}
