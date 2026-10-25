package com.zentrapay.backend.service.region;

import com.zentrapay.backend.entity.GatewayCountryModel;
import com.zentrapay.backend.entity.GatewayCurrencyModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.repository.GatewayCountriesRepository;
import com.zentrapay.backend.repository.GatewayCurrenciesRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;

/**
 * The one place that answers "does ZentraPay operate here?".
 *
 * <p>The answer comes from {@code gateway_countries} / {@code gateway_currencies}, which the
 * scheduled directory sync keeps in line with what Paystack, Flutterwave and Onafriq report as
 * supported. A user can only register from, send from and send to an ACTIVE country, and only in
 * ACTIVE currencies.
 */
@Service
@RequiredArgsConstructor
public class SupportedRegionService {

    private final GatewayCountriesRepository gatewayCountriesRepository;
    private final GatewayCurrenciesRepository gatewayCurrenciesRepository;

    /** True when the country is in the directory and switched on. */
    public boolean isCountrySupported(String countryCode) {
        return findActiveCountry(countryCode) != null;
    }

    /** Every active country code (upper case) - used to limit searches to places we can pay. */
    public List<String> activeCountryCodes() {
        return gatewayCountriesRepository.findByActive(true).stream()
                .map(c -> c.getCountryCode().toUpperCase(Locale.ROOT))
                .toList();
    }

    /** The active country row, or an error naming the country that is not supported. */
    public GatewayCountryModel requireCountry(String countryCode) {
        GatewayCountryModel country = findActiveCountry(countryCode);
        if (country == null) {
            throw new IllegalArgumentException("ZentraPay is not available in "
                    + (countryCode == null || countryCode.isBlank() ? "that country" : countryCode.trim().toUpperCase(Locale.ROOT))
                    + " yet. Please choose a supported country.");
        }
        return country;
    }

    /** Registration / sending: the user's own country must be supported. */
    public void requireUserCountry(UserModel user) {
        if (!isCountrySupported(user.getCountryCode())) {
            throw new IllegalArgumentException("ZentraPay is not available in your country ("
                    + user.getCountryCode().toUpperCase(Locale.ROOT) + ") at the moment, so this transaction cannot go ahead.");
        }
    }

    /** The currency must be in the directory and switched on. */
    public GatewayCurrencyModel requireCurrency(String currencyCode) {
        String code = currencyCode == null ? "" : currencyCode.trim().toUpperCase(Locale.ROOT);
        return gatewayCurrenciesRepository.findById(code)
                .filter(GatewayCurrencyModel::isActive)
                .orElseThrow(() -> new IllegalArgumentException("We currently don't support "
                        + (code.isEmpty() ? "that currency" : code) + " transfers. Please choose another currency"));
    }

    private GatewayCountryModel findActiveCountry(String countryCode) {
        if (countryCode == null || countryCode.isBlank()) {
            return null;
        }
        return gatewayCountriesRepository.findFirstByCountryCode(countryCode.trim().toUpperCase(Locale.ROOT))
                .filter(GatewayCountryModel::isActive)
                .orElse(null);
    }
}
