package com.zentrapay.backend.service.DigitalAccounts;

import com.zentrapay.backend.dto.wallet.*;
import com.zentrapay.backend.repository.CurrenciesRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

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

    @Transactional(readOnly = true)
    public List<SupportedCurrencyDTO> getCurrencies() {
        return currencies.findAll().stream().map(c -> new SupportedCurrencyDTO(
                c.getCode(),
                c.getCurrencyName()
        )).toList();
    }

    public void requireSupportedCurrency(String currencyCode) {
        if (!currencies.existsByCurrencyCode(currencyCode)) {
            throw new RuntimeException("Currency not supported.");
        }
    }

    @Transactional(readOnly = true)
    public String getCurrency(String countryCode) {
        return currencies.getCurrencyCodeByCountryCode(countryCode);
    }


}
