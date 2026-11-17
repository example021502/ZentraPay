package com.zentrapay.backend.service.wallet;

import com.zentrapay.backend.dto.wallet.*;
import com.zentrapay.backend.entity.CryptoWalletModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.entity.UserProfileModel;
import com.zentrapay.backend.entity.VirtualAccountModel;
import com.zentrapay.backend.repository.CryptoAccountRepository;
import com.zentrapay.backend.repository.CryptoWalletRepository;
import com.zentrapay.backend.repository.CurrenciesRepository;
import com.zentrapay.backend.repository.VirtualAccountRepository;
import com.zentrapay.backend.service.common.Utils;
import com.zentrapay.backend.service.gateway.FincraServices;
import com.zentrapay.backend.service.region.SupportedRegionService;
import com.zentrapay.backend.service.user.UserProfileServices;
import com.zentrapay.backend.service.user.UsersService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class CurrenciesServices {

    private final CurrenciesRepository currencies;


    // Fetches the authenticated user's fiat wallets (wallets table) and crypto
    // wallets (crypto_wallets table) in the exact shape the frontend expects.
    @Transactional(readOnly = true)
    public List<SupportedCurrencyDTO> getCurrencies(List<String> codes) {
        // Collects the fiat and crypto accounts with their balances for the home screen
        log.info("===== EXTRACTING THE CURRENCIES FROM THE CURRENCIES TABLE ======");

        return currencies.getCurrenciesByCodes(codes).stream()
                .map(c -> new SupportedCurrencyDTO(
                        c.getCode(),
                        c.getCurrencyName()
                )).toList();
    }


}
