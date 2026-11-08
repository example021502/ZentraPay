package com.zentrapay.backend.service.fx;

import com.zentrapay.backend.dto.converter.ConverterDTOs.*;
import com.zentrapay.backend.entity.ConversionModel;
import com.zentrapay.backend.repository.ConversionRepository;
import com.zentrapay.backend.repository.FiatAccountRepository;
import com.zentrapay.backend.repository.FiatWalletRepository;
import com.zentrapay.backend.service.region.SupportedRegionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * The converter screen: live rates, a one-off conversion and the user's conversion history.
 * Nothing here moves money - it only reads rates and records what the user looked up.
 *
 * <p>A conversion is only allowed between two currencies the user holds a wallet account in. A missing
 * account is refused with a message asking them to create it first.
 */
@Service
@RequiredArgsConstructor
public class ConverterService {

    private final ExchangeRateService exchangeRateService;
    private final SupportedRegionService supportedRegionService;
    private final ConversionRepository conversionRepository;
    private final FiatWalletRepository fiatWalletRepository;
    private final FiatAccountRepository fiatAccountRepository;

    /** The rate from {@code base} to every supported currency that has a rate. */
    public RatesDTO rates(String base) {
        String baseCode = base.trim().toUpperCase();
        Map<String, String> rates = new LinkedHashMap<>();
        for (String currency : supportedRegionService.supportedCurrencyCodes()) {
            if (currency.equalsIgnoreCase(baseCode)) {
                continue;
            }
            try {
                rates.put(currency, exchangeRateService.rate(baseCode, currency)
                        .setScale(6, RoundingMode.HALF_UP).toPlainString());
            } catch (IllegalArgumentException noRate) {
                // No rate for this pair yet - leave it out of the list
            }
        }
        return new RatesDTO(baseCode, rates);
    }

    /** Converts an amount and saves it in the user's history. Both currencies need a wallet account. */
    public ConvertResponseDTO convert(UUID userId, ConvertRequestDTO request) {
        String from = request.from().trim().toUpperCase();
        String to = request.to().trim().toUpperCase();
        requireWalletAccounts(userId, from, to);
        BigDecimal rate = exchangeRateService.rate(from, to);
        BigDecimal converted = request.amount().multiply(rate).setScale(2, RoundingMode.HALF_UP);

        ConversionModel row = new ConversionModel();
        row.setUserId(userId);
        row.setFromCurrencyCode(from);
        row.setToCurrencyCode(to);
        row.setAmount(request.amount());
        row.setConvertedAmount(converted);
        row.setRate(rate);
        conversionRepository.save(row);
        return new ConvertResponseDTO(converted, rate);
    }

    // Refuses (naming the missing currencies) unless the user holds a wallet account in each one
    private void requireWalletAccounts(UUID userId, String... currencies) {
        UUID walletId = fiatWalletRepository.getWalletIdByUserId(userId).orElse(null);
        List<String> missing = new ArrayList<>();
        for (String currency : currencies) {
            boolean has = walletId != null && fiatAccountRepository.existsByWalletIdAndCurrencyCode(walletId, currency);
            if (!has && !missing.contains(currency)) {
                missing.add(currency);
            }
        }
        if (!missing.isEmpty()) {
            throw new IllegalArgumentException(missing.size() == 1
                    ? "You don't have a " + missing.get(0) + " wallet account yet. Create it first, then convert."
                    : "You don't have " + String.join(" and ", missing) + " wallet accounts yet. Create them first, then convert.");
        }
    }

    /** The latest conversions of a user, newest first. */
    public List<ConversionHistoryDTO> history(UUID userId) {
        return conversionRepository.findTop50ByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(c -> new ConversionHistoryDTO(c.getFromCurrencyCode(), c.getToCurrencyCode(),
                        c.getAmount(), c.getConvertedAmount(), c.getCreatedAt()))
                .toList();
    }
}
