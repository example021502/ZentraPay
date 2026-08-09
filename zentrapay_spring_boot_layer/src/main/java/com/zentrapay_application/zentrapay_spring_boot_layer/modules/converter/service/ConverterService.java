package com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.dto.ConversionHistoryDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.dto.ConvertResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.model.Conversion;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.repository.ConversionRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.repository.ExchangeRateRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

/**
 * Real currency conversion backed by the {@code exchange_rates} table (replaces the old
 * in-memory static rate map). A pair's "current" rate is the row with the latest
 * effective_at. If a direct row isn't seeded for a pair, falls back to the inverse of
 * the opposite-direction row, then to triangulation through USD — this mirrors how a
 * small seeded rate table (see V5__seed_exchange_rates.sql) can still answer any
 * cross-currency pair without needing every directed pair pre-seeded.
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ConverterService {

    private static final String PIVOT = "USD";
    private static final java.util.List<String> DEFAULT_BASE_CURRENCIES =
            java.util.List.of("GHS", "NGN", "KES", "ZAR", "USD", "EUR", "GBP");

    private final ExchangeRateRepository exchangeRateRepository;
    private final ConversionRepository conversionRepository;

    public Map<String, BigDecimal> getRates(String base) {
        String baseCode = base == null || base.isBlank() ? PIVOT : base.toUpperCase();
        Map<String, BigDecimal> rates = new LinkedHashMap<>();
        for (String quote : DEFAULT_BASE_CURRENCIES) {
            if (quote.equals(baseCode)) {
                continue;
            }
            findRate(baseCode, quote).ifPresent(r -> rates.put(quote, r));
        }
        return rates;
    }

    public BigDecimal getRate(String from, String to) {
        String fromCode = from.toUpperCase();
        String toCode = to.toUpperCase();
        return findRate(fromCode, toCode)
                .orElseThrow(() -> new IllegalArgumentException("No exchange rate available for " + fromCode + " -> " + toCode));
    }

    @Transactional
    public ConvertResponseDTO convert(UUID userId, String from, String to, BigDecimal amount) {
        String fromCode = from.toUpperCase();
        String toCode = to.toUpperCase();
        BigDecimal rate = getRate(fromCode, toCode);
        BigDecimal converted = amount.multiply(rate).setScale(4, RoundingMode.HALF_UP);

        Conversion conversion = new Conversion();
        conversion.setUserId(userId);
        conversion.setFromCurrencyCode(fromCode);
        conversion.setToCurrencyCode(toCode);
        conversion.setAmount(amount);
        conversion.setConvertedAmount(converted);
        conversion.setRate(rate);
        conversionRepository.save(conversion);

        return new ConvertResponseDTO(converted, rate);
    }

    public java.util.List<ConversionHistoryDTO> getHistory(UUID userId) {
        return conversionRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(c -> new ConversionHistoryDTO(c.getFromCurrencyCode(), c.getToCurrencyCode(), c.getAmount(),
                        c.getConvertedAmount(), c.getCreatedAt()))
                .toList();
    }

    /**
     * Resolves the latest rate for {@code from -> to}: direct row, else inverse of the
     * opposite row, else triangulated through USD.
     */
    private Optional<BigDecimal> findRate(String from, String to) {
        if (from.equals(to)) {
            return Optional.of(BigDecimal.ONE);
        }
        Optional<BigDecimal> direct = latestDirect(from, to);
        if (direct.isPresent()) {
            return direct;
        }
        Optional<BigDecimal> inverse = latestDirect(to, from);
        if (inverse.isPresent()) {
            return Optional.of(BigDecimal.ONE.divide(inverse.get(), 10, RoundingMode.HALF_UP));
        }
        if (!from.equals(PIVOT) && !to.equals(PIVOT)) {
            Optional<BigDecimal> fromToPivot = findRate(from, PIVOT);
            Optional<BigDecimal> pivotToTarget = findRate(PIVOT, to);
            if (fromToPivot.isPresent() && pivotToTarget.isPresent()) {
                return Optional.of(fromToPivot.get().multiply(pivotToTarget.get()).setScale(10, RoundingMode.HALF_UP));
            }
        }
        return Optional.empty();
    }

    private Optional<BigDecimal> latestDirect(String from, String to) {
        return exchangeRateRepository
                .findFirstByBaseCurrencyCodeAndQuoteCurrencyCodeOrderByEffectiveAtDesc(from, to)
                .map(com.zentrapay_application.zentrapay_spring_boot_layer.modules.converter.model.ExchangeRate::getRate);
    }
}
