package com.zentrapay.backend.service.fx;

import com.zentrapay.backend.entity.ExchangeRateModel;
import com.zentrapay.backend.repository.ExchangeRatesRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Optional;

/**
 * The one place that turns "GHS -> NGN" into a rate and an amount, so payments,
 * remittances and the converter screen can never disagree.
 *
 * <p>Rates come from the {@code exchange_rates} table (latest row per pair).
 * A pair is resolved in this order: direct row, inverse of the opposite row,
 * then triangulation through USD.
 */
@Service
@RequiredArgsConstructor
public class ExchangeRateService {

    private static final String PIVOT = "USD";

    private final ExchangeRatesRepository exchangeRatesRepository;

    /** The current rate to multiply a {@code from} amount by to get a {@code to} amount. */
    public BigDecimal rate(String from, String to) {
        if (from.equalsIgnoreCase(to)) {
            return BigDecimal.ONE;
        }

        Optional<ExchangeRateModel> direct = latest(from, to);
        if (direct.isPresent()) {
            return direct.get().getRate();
        }

        Optional<ExchangeRateModel> inverse = latest(to, from);
        if (inverse.isPresent() && inverse.get().getRate().signum() != 0) {
            return BigDecimal.ONE.divide(inverse.get().getRate(), 10, RoundingMode.HALF_UP);
        }

        Optional<ExchangeRateModel> fromToPivot = latest(from, PIVOT);
        Optional<ExchangeRateModel> pivotToTarget = latest(PIVOT, to);
        if (fromToPivot.isPresent() && pivotToTarget.isPresent()) {
            return fromToPivot.get().getRate().multiply(pivotToTarget.get().getRate()).setScale(10, RoundingMode.HALF_UP);
        }

        throw new IllegalArgumentException("No exchange rate available for " + from.toUpperCase()
                + " to " + to.toUpperCase() + " at the moment. Please try again later");
    }

    /** Converts an amount, rounded to 2 decimals (money is never kept with more). */
    public BigDecimal convert(BigDecimal amount, String from, String to) {
        return amount.multiply(rate(from, to)).setScale(2, RoundingMode.HALF_UP);
    }

    /**
     * Checks a rate id sent by the app against the live rate. The app shows the user a
     * rate before they pay; if it has changed since, the payment must not silently use another one.
     */
    public void assertRateStillCurrent(java.util.UUID rateId, String from, String to) {
        ExchangeRateModel quoted = exchangeRatesRepository.findById(rateId)
                .orElseThrow(() -> new IllegalArgumentException("Exchange rate not found, please refresh and try again"));

        boolean sameDirection = quoted.getBaseCurrencyCode().equalsIgnoreCase(from) && quoted.getQuoteCurrencyCode().equalsIgnoreCase(to);
        boolean oppositeDirection = quoted.getBaseCurrencyCode().equalsIgnoreCase(to) && quoted.getQuoteCurrencyCode().equalsIgnoreCase(from);
        if (!sameDirection && !oppositeDirection) {
            throw new IllegalArgumentException("The exchange rate does not match the currencies of this payment");
        }

        BigDecimal quotedRate = sameDirection
                ? quoted.getRate()
                : BigDecimal.ONE.divide(quoted.getRate(), 10, RoundingMode.HALF_UP);
        if (quotedRate.compareTo(rate(from, to)) != 0) {
            throw new IllegalArgumentException("The exchange rate has changed, please refresh and try again");
        }
    }

    private Optional<ExchangeRateModel> latest(String base, String quote) {
        return exchangeRatesRepository
                .findFirstByBaseCurrencyCodeIgnoreCaseAndQuoteCurrencyCodeIgnoreCaseOrderByEffectiveAtDesc(base, quote);
    }
}
