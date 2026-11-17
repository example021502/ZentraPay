package com.zentrapay.backend.service.region;

import com.zentrapay.backend.entity.CountriesModel;
import com.zentrapay.backend.entity.CurrenciesModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.repository.CurrenciesRepository;
import com.zentrapay.backend.service.Countries.CountriesServices;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Locale;

/**
 * The one place that answers "does ZentraPay operate here, and in which currency?".
 *
 * <p>Everything comes from {@code gateway_countries}, which the scheduled directory sync keeps in line
 * with what Paystack, Flutterwave and Onafriq report as supported. A user can only register from, send
 * from and send to an ACTIVE country.
 *
 * <p>Currencies are restricted by the country's {@code default_currency}, not by a currencies table:
 * <ul>
 *   <li>domestic payment: the sender pays in the default currency of the country they registered in, and
 *       the recipient (same country) receives that same currency;</li>
 *   <li>cross-border payment: the sender still pays in their own country's default currency, and the
 *       money arrives in the destination country's default currency.</li>
 * </ul>
 */
@Service
@RequiredArgsConstructor
public class SupportedRegionService {

    private final GatewayCountriesRepository gatewayCountriesRepository;
    private final CurrenciesRepository currenciesRepository;
    private final CountriesServices countriesServices;

    /**
     * The currencies a payment is made in for one send: what the sender is debited in and what arrives.
     */
    public record PaymentCurrencies(String source, String destination) {
        public boolean sameCurrency() {
            return source.equalsIgnoreCase(destination);
        }
    }

    /**
     * True when the country is in the directory and switched on.
     */
    public boolean isCountrySupported(String countryCode) {
        return findActiveCountry(countryCode) != null;
    }

    /**
     * Every active country code (upper case) - used to limit searches to places we can pay.
     */
    public List<String> activeCountryCodes() {
        return gatewayCountriesRepository.findByActive(true).stream()
                .map(c -> c.getCode().toUpperCase(Locale.ROOT))
                .toList();
    }

    /**
     * The active country row, or an error naming the country that is not supported.
     */
    public CountriesModel requireCountry(String countryCode) {
        CountriesModel country = findActiveCountry(countryCode);
        if (country == null) {
            throw new IllegalArgumentException("ZentraPay is not available in "
                    + (countryCode == null || countryCode.isBlank() ? "that country" : countryCode.trim().toUpperCase(Locale.ROOT))
                    + " yet. Please choose a supported country.");
        }
        return country;
    }

    /**
     * Registration / sending: the user's own country must be supported.
     */
    public void requireUserCountry(UserModel sender) {
        if (!isCountrySupported(sender.getCountryCode())) {
            throw new IllegalArgumentException("ZentraPay is not available in your country ("
                    + sender.getCountryCode().toUpperCase(Locale.ROOT) + ") at the moment, so this transaction cannot go ahead.");
        }
    }

    // ------------------------------------------------------------------
    // Currencies - all derived from the countries' default_currency
    // ------------------------------------------------------------------

    /**
     * The default currency (upper case) of an active country.
     */
    public String defaultCurrencyOf(String countryCode) {
        return defaultCurrencyOf(requireCountry(countryCode));
    }

    /**
     * The default currency (upper case) of a country row.
     */
    public String defaultCurrencyOf(CountriesModel country) {
        CurrenciesModel currency = currenciesRepository.getCurrencyByCountryCode(country.getCode())
                .orElseThrow(() -> new RuntimeException("Currency not found."));
        return currency.getCode();
    }

    /**
     * Every currency ZentraPay can move money in: the distinct default currencies of the active countries.
     */
    public List<String> supportedCurrencyCodes() {
        return gatewayCountriesRepository.findActiveDefaultCurrencies().stream()
                .filter(code -> code != null && !code.isBlank())
                .map(String::trim)
                .distinct()
                .sorted()
                .toList();
    }

    /**
     * The country codes that use this currency as their default (XOF is shared by several).
     */
    public List<String> countriesUsing(String currencyCode) {
        return countriesServices.getCountriesByCurrencyCode(currencyCode);
    }

    /**
     * The currency must be one some active country uses as its default.
     */
    public String requireSupportedCurrency(String currencyCode) {
        String code = currencyCode == null ? "" : currencyCode.trim().toUpperCase(Locale.ROOT);
        if (code.isEmpty() || !supportedCurrencyCodes().contains(code)) {
            throw new IllegalArgumentException("We currently don't support "
                    + (code.isEmpty() ? "that currency" : code) + " transfers. Please choose another currency");
        }
        return code;
    }

    /**
     * Applies the currency restriction to one payment and returns the currencies it settles in.
     *
     * <p>The sender is debited in the default currency of the country they are registered in. The recipient
     * receives the default currency of the destination country - the sender's own country for a domestic
     * payment, the other country for a cross-border one. A currency the app asked for that is not allowed is
     * refused; a blank one just takes the allowed default.
     *
     * @param destinationCountryCode where the money goes (blank = the sender's own country)
     * @param requestedSource        the currency the app wants to debit, if it named one
     * @param requestedDestination   the currency the app expects to arrive, if it named one
     */
    public PaymentCurrencies currenciesFor(UserModel sender, String destinationCountryCode,
                                           String requestedSource, String requestedDestination) {
        requireUserCountry(sender);
        CountriesModel home = requireCountry(sender.getCountryCode());
        String source = defaultCurrencyOf(home);

        if (isGiven(requestedSource) && !source.equalsIgnoreCase(requestedSource.trim())) {
            throw new IllegalArgumentException("You are registered in " + home.getCountryName() + ", so payments from your account are made in "
                    + source + ", not " + requestedSource.trim().toUpperCase(Locale.ROOT) + ".");
        }

        boolean domestic = !isGiven(destinationCountryCode) || home.getCountryCode().equalsIgnoreCase(destinationCountryCode.trim());
        CountriesModel destinationCountry = domestic ? home : requireCountry(destinationCountryCode);
        String destination = defaultCurrencyOf(destinationCountry);

        if (isGiven(requestedDestination) && !destination.equalsIgnoreCase(requestedDestination.trim())) {
            throw new IllegalArgumentException((domestic
                    ? "Payments within " + home.getCountryName() + " are made in " + destination
                    : "Money sent to " + destinationCountry.getCountryName() + " arrives in " + destination)
                    + ", not " + requestedDestination.trim().toUpperCase(Locale.ROOT) + ".");
        }
        return new PaymentCurrencies(source, destination);
    }

    private static boolean isGiven(String value) {
        return value != null && !value.isBlank();
    }

    private CountriesModel findActiveCountry(String countryCode) {
        if (countryCode == null || countryCode.isBlank()) {
            return null;
        }
        return gatewayCountriesRepository.findFirstByCountryCode(countryCode.trim().toUpperCase(Locale.ROOT))
                .filter(CountriesModel::isActive)
                .orElse(null);
    }
}
