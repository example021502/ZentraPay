package com.zentrapay.backend.service.fx;

import com.zentrapay.backend.dto.converter.ConverterDTOs.*;
import com.zentrapay.backend.entity.ConversionModel;
import com.zentrapay.backend.entity.GatewayCurrencyModel;
import com.zentrapay.backend.repository.ConversionRepository;
import com.zentrapay.backend.repository.GatewayCurrenciesRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * The converter screen: live rates, a one-off conversion and the user's conversion history.
 * Nothing here moves money - it only reads rates and records what the user looked up.
 */
@Service
@RequiredArgsConstructor
public class ConverterService {

    private final ExchangeRateService exchangeRateService;
    private final GatewayCurrenciesRepository gatewayCurrenciesRepository;
    private final ConversionRepository conversionRepository;

    /** The rate from {@code base} to every supported currency that has a rate. */
    public RatesDTO rates(String base) {
        String baseCode = base.trim().toUpperCase();
        Map<String, String> rates = new LinkedHashMap<>();
        for (GatewayCurrencyModel currency : gatewayCurrenciesRepository.findByActive(true)) {
            if (currency.getCurrencyCode().equalsIgnoreCase(baseCode)) {
                continue;
            }
            try {
                rates.put(currency.getCurrencyCode(), exchangeRateService.rate(baseCode, currency.getCurrencyCode())
                        .setScale(6, RoundingMode.HALF_UP).toPlainString());
            } catch (IllegalArgumentException noRate) {
                // No rate for this pair yet - leave it out of the list
            }
        }
        return new RatesDTO(baseCode, rates);
    }

    /** Converts an amount and saves it in the user's history. */
    public ConvertResponseDTO convert(UUID userId, ConvertRequestDTO request) {
        String from = request.from().trim().toUpperCase();
        String to = request.to().trim().toUpperCase();
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

    /** The latest conversions of a user, newest first. */
    public List<ConversionHistoryDTO> history(UUID userId) {
        return conversionRepository.findTop50ByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(c -> new ConversionHistoryDTO(c.getFromCurrencyCode(), c.getToCurrencyCode(),
                        c.getAmount(), c.getConvertedAmount(), c.getCreatedAt()))
                .toList();
    }
}
