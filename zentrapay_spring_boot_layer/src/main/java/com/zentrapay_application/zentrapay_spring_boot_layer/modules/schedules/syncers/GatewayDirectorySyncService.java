package com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.syncers;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayCountryModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.GatewayCurrencyModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.GatewayCountriesRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.GatewayCurrenciesRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos.FlutterwaveBankResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos.OnafriqBankResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.schedules.dtos.PaystackBankResponseDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.TreeSet;

/**
 * Keeps {@code gateway_countries} / {@code gateway_currencies} — the canonical
 * "what can ZentraPay move money in" directory — populated from what the
 * connected gateways actually report as supported.
 * <p>
 * Strategy per configured country: ask Paystack ({@code /bank?country=XX}),
 * Flutterwave ({@code /banks/XX}) and Onafriq
 * ({@code /api/financial-institutions?country=XX}). A gateway answering with
 * data proves it supports that country; the currency codes carried by the
 * returned banks prove it supports those currencies. Results merge into
 * idempotent upserts so repeated runs simply refresh the rows.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class GatewayDirectorySyncService {

    private final RestTemplate restTemplate = new RestTemplate();
    private final GatewayCountriesRepository gatewayCountriesRepository;
    private final GatewayCurrenciesRepository gatewayCurrenciesRepository;

    @Value("${paystack.base-url}")
    String paystackBaseUrl;
    @Value("${paystack.secret-key}")
    String paystackSk;
    @Value("${flutterwave.base-url}")
    String flutterwaveBaseUrl;
    @Value("${flutterwave.secret-key}")
    String flutterwaveSk;
    @Value("${onafriq.base-url}")
    String onafriqBaseUrl;
    @Value("${onafriq.secret-key}")
    String onafriqSk;

    /** Countries to probe; configurable so coverage can grow without a redeploy. */
    @Value("${app.gateway.countries:GH,NG,KE,TZ,UG,RW,ZA,CI,SN,CM}")
    String configuredCountries;

    // Static reference metadata: gateways prove *support*; this map supplies
    // display names, dial codes and default currencies so the tables stay
    // self-describing for the frontend pickers.
    private static final Map<String, CountryMeta> COUNTRY_META = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
    private static final Map<String, CurrencyMeta> CURRENCY_META = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);

    static {
        register("GH", "Ghana", "GHA", "+233", "West Africa", "GHS");
        register("NG", "Nigeria", "NGA", "+234", "West Africa", "NGN");
        register("KE", "Kenya", "KEN", "+254", "East Africa", "KES");
        register("TZ", "Tanzania", "TZA", "+255", "East Africa", "TZS");
        register("UG", "Uganda", "UGA", "+256", "East Africa", "UGX");
        register("RW", "Rwanda", "RWA", "+250", "East Africa", "RWF");
        register("ZA", "South Africa", "ZAF", "+27", "Southern Africa", "ZAR");
        register("CI", "Ivory Coast", "CIV", "+225", "West Africa", "XOF");
        register("SN", "Senegal", "SEN", "+221", "West Africa", "XOF");
        register("CM", "Cameroon", "CMR", "+237", "Central Africa", "XAF");

        currency("GHS", "Ghanaian Cedi", "GH\u20b5", 2, "GH");
        currency("NGN", "Nigerian Naira", "\u20a6", 2, "NG");
        currency("KES", "Kenyan Shilling", "KSh", 2, "KE");
        currency("TZS", "Tanzanian Shilling", "TSh", 2, "TZ");
        currency("UGX", "Ugandan Shilling", "USh", 0, "UG");
        currency("RWF", "Rwandan Franc", "FRw", 0, "RW");
        currency("ZAR", "South African Rand", "R", 2, "ZA");
        currency("XOF", "West African CFA Franc", "CFA", 0, "");
        currency("XAF", "Central African CFA Franc", "FCFA", 0, "");
        currency("USD", "US Dollar", "$", 2, "");
        currency("EUR", "Euro", "\u20ac", 2, "");
        currency("GBP", "British Pound", "\u00a3", 2, "");
    }

    private static void register(String code, String name, String iso3, String dial, String region, String curr) {
        COUNTRY_META.put(code, new CountryMeta(name, iso3, dial, region, curr));
    }

    private static void currency(String code, String name, String symbol, int decimals, String homeCountry) {
        CURRENCY_META.put(code, new CurrencyMeta(name, symbol, decimals, homeCountry));
    }

    /**
     * Entry point used by the scheduler: probes every configured country
     * against all three gateways and rebuilds both directory tables.
     * Populated on every boot and refreshed daily so the directory always
     * mirrors what the gateways actually support.
     */
    @EventListener(ApplicationReadyEvent.class)
    @Scheduled(cron = "0 0 2 * * *", zone = "UTC")
    @Transactional
    public void refreshGatewayDirectory() {
        final LocalDateTime now = LocalDateTime.now();

        // countryCode -> gateways proving support for it
        Map<String, Set<String>> countryGateways = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);
        // countryCode -> currency codes proven by that country's bank lists
        Map<String, Set<String>> countryCurrencies = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);

        for (String raw : configuredCountries.split(",")) {
            String cc = raw.trim();
            if (cc.isEmpty()) continue;
            probePaystack(cc.toUpperCase(), countryGateways, countryCurrencies);
            probeFlutterwave(cc.toUpperCase(), countryGateways, countryCurrencies);
            probeOnafriq(cc.toUpperCase(), countryGateways, countryCurrencies);
        }

        // Cold-start fallback: gateways unreachable (no keys offline / network)
        // — seed the configured launch corridors marked 'bootstrap' so
        // registration and wallet creation still work until the next run.
        if (countryGateways.isEmpty()) {
            for (String raw : configuredCountries.split(",")) {
                String cc = raw.trim().toUpperCase();
                if (!cc.isEmpty()) {
                    countryGateways.computeIfAbsent(cc, k -> new LinkedHashSet<>()).add("bootstrap");
                }
            }
        }

        Set<String> activeCurrencyCodes = new TreeSet<>(String.CASE_INSENSITIVE_ORDER);
        for (Map.Entry<String, Set<String>> e : countryGateways.entrySet()) {
            String countryCode = e.getKey().toUpperCase();
            CountryMeta meta = COUNTRY_META.get(countryCode);
            String defaultCurrency = meta != null ? meta.defaultCurrency() : "USD";

            upsertCountry(countryCode, defaultCurrency,
                    String.join(",", e.getValue()).toLowerCase(), now);

            // Every proven currency plus the country's default are active.
            activeCurrencyCodes.add(defaultCurrency);
            countryCurrencies.getOrDefault(countryCode, Set.of())
                    .forEach(cur -> activeCurrencyCodes.add(cur.toUpperCase()));
        }
        activeCurrencyCodes.forEach(c -> upsertCurrency(c, now));
        deactivateStale(activeCurrencyCodes);
        log.info("Gateway directory refreshed: {} countries, {} currencies",
                countryGateways.size(), activeCurrencyCodes.size());
    }

        // ------------------------------------------------------------------
    // Gateway probes
    // ------------------------------------------------------------------

    private void probePaystack(String cc, Map<String, Set<String>> countryGateways,
                               Map<String, Set<String>> countryCurrencies) {
        String url = paystackBaseUrl + "/bank?country=" + cc;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + paystackSk);
        try {
            ResponseEntity<PaystackBankResponseDTO> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), PaystackBankResponseDTO.class);
            if (response.getBody() != null && response.getBody().status()) {
                countryGateways.computeIfAbsent(cc, k -> new LinkedHashSet<>()).add("paystack");
                collectCurrencies(cc, response.getBody().data(), countryCurrencies);
            }
        } catch (Exception e) {
            log.warn("Paystack probe failed for {}: {}", cc, e.getMessage());
        }
    }

    private void probeFlutterwave(String cc, Map<String, Set<String>> countryGateways,
                                  Map<String, Set<String>> countryCurrencies) {
        String url = flutterwaveBaseUrl + "/banks/" + cc;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + flutterwaveSk);
        try {
            ResponseEntity<FlutterwaveBankResponseDTO> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), FlutterwaveBankResponseDTO.class);
            if (response.getBody() != null && "success".equalsIgnoreCase(response.getBody().status())) {
                countryGateways.computeIfAbsent(cc, k -> new LinkedHashSet<>()).add("flutterwave");
                registerDefaultCurrency(cc, countryCurrencies);
            }
        } catch (Exception e) {
            log.warn("Flutterwave probe failed for {}: {}", cc, e.getMessage());
        }
    }

    private void probeOnafriq(String cc, Map<String, Set<String>> countryGateways,
                              Map<String, Set<String>> countryCurrencies) {
        String url = onafriqBaseUrl + "/api/financial-institutions?country=" + cc;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + onafriqSk);
        headers.set("Accept", "application/json");
        try {
            ResponseEntity<OnafriqBankResponseDTO> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), OnafriqBankResponseDTO.class);
            if (response.getBody() != null) {
                countryGateways.computeIfAbsent(cc, k -> new LinkedHashSet<>()).add("onafriq");
            }
        } catch (Exception e) {
            log.warn("Onafriq probe failed for {}: {}", cc, e.getMessage());
        }
    }

    // ------------------------------------------------------------------
    // Persistence helpers
    // ------------------------------------------------------------------

    /** Extracts currency codes from Paystack's bank list (only gateway that returns them). */
    private void collectCurrencies(String cc, List<PaystackBankResponseDTO.BankItemDTO> items,
                                   Map<String, Set<String>> countryCurrencies) {
        for (PaystackBankResponseDTO.BankItemDTO item : items) {
            if (item != null && item.currency() != null && !item.currency().isBlank()) {
                countryCurrencies.computeIfAbsent(cc, k -> new LinkedHashSet<>())
                        .add(item.currency().trim().toUpperCase());
            }
        }
        // Fall back to the registered default so the corridor is always represented.
        countryCurrencies.computeIfAbsent(cc, k -> {
            CountryMeta meta = COUNTRY_META.get(cc);
            Set<String> fallback = new LinkedHashSet<>();
            if (meta != null) {
                fallback.add(meta.defaultCurrency());
            }
            return fallback;
        });
    }

    private void upsertCountry(String countryCode, String currencyCode, String gateways, LocalDateTime now) {
        GatewayCountryModel row = gatewayCountriesRepository.findById(countryCode)
                .orElseGet(() -> {
                    GatewayCountryModel fresh = new GatewayCountryModel();
                    fresh.setCountryCode(countryCode);
                    fresh.setCreatedAt(now);
                    return fresh;
                });
        CountryMeta meta = COUNTRY_META.get(countryCode);
        row.setCountryName(meta != null ? meta.name() : countryCode);
        row.setIso3Code(meta != null ? meta.iso3() : countryCode);
        row.setDialCode(meta != null ? meta.dial() : "");
        row.setRegion(meta != null ? meta.region() : "");
        row.setCurrencyCode(currencyCode);
        row.setGateways(gateways);
        row.setDefault("GH".equalsIgnoreCase(countryCode));
        row.setActive(true);
        row.setUpdatedAt(now);
        gatewayCountriesRepository.save(row);
    }

    /**
     * Registers the country's default currency so the corridor is always
     * represented in the directory even when the gateway's bank list carries
     * no usable currency codes.
     */
    private void registerDefaultCurrency(String cc, Map<String, Set<String>> countryCurrencies) {
        CountryMeta meta = COUNTRY_META.get(cc);
        if (meta != null) {
            countryCurrencies.computeIfAbsent(cc, k -> new LinkedHashSet<>()).add(meta.defaultCurrency());
        }
    }

    private void upsertCurrency(String code, LocalDateTime now) {
        CurrencyMeta meta = CURRENCY_META.get(code);
        GatewayCurrencyModel row = gatewayCurrenciesRepository.findById(code)
                .orElseGet(() -> {
                    GatewayCurrencyModel fresh = new GatewayCurrencyModel();
                    fresh.setCurrencyCode(code);
                    fresh.setCreatedAt(now);
                    return fresh;
                });
        row.setCurrencyName(meta != null ? meta.name() : code);
        row.setSymbol(meta != null ? meta.symbol() : code);
        row.setCrypto(false);
        row.setDecimalPlaces((short) (meta != null ? meta.decimals() : 2));
        row.setCountryCode(meta != null ? meta.homeCountry() : "");
        row.setGateways(row.getGateways() == null || row.getGateways().isBlank()
                ? "flutterwave" : row.getGateways());
        row.setDefault("GHS".equalsIgnoreCase(code));
        row.setActive(true);
        row.setUpdatedAt(now);
        gatewayCurrenciesRepository.save(row);
    }

    /** Soft-deactivates rows the gateways no longer prove support for. */
    private void deactivateStale(Set<String> activeCurrencyCodes) {
        final LocalDateTime now = LocalDateTime.now();
        for (GatewayCurrencyModel existing : gatewayCurrenciesRepository.findAll()) {
            if (existing.isActive() && !activeCurrencyCodes.contains(existing.getCurrencyCode())) {
                existing.setActive(false);
                existing.setUpdatedAt(now);
                gatewayCurrenciesRepository.save(existing);
            }
        }
    }

    // ------------------------------------------------------------------
    // Static reference metadata records
    // ------------------------------------------------------------------

    private record CountryMeta(String name, String iso3, String dial, String region, String defaultCurrency) {}

    private record CurrencyMeta(String name, String symbol, int decimals, String homeCountry) {}
}