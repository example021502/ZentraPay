package com.zentrapay.backend.service.schedule.sync;

import com.zentrapay.backend.entity.CountriesModel;
import com.zentrapay.backend.dto.schedules.FlutterwaveBankResponseDTO;
import com.zentrapay.backend.dto.schedules.OnafriqBankResponseDTO;
import com.zentrapay.backend.dto.schedules.PaystackBankResponseDTO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.LinkedHashSet;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;

/**
 * Keeps {@code gateway_countries} - the one "where can ZentraPay move money" table - populated from what
 * the connected gateways actually report as supported.
 * <p>
 * Strategy per configured country: ask Paystack ({@code /bank?country=XX}),
 * Flutterwave ({@code /banks/XX}) and Onafriq
 * ({@code /api/financial-institutions?country=XX}). A gateway answering with
 * data proves it supports that country. Results merge into idempotent upserts so repeated runs simply
 * refresh the rows.
 * <p>
 * Each country row carries its {@code default_currency}, which restricts payments. The sync only fills it
 * in for a country it creates; a value that is already there (seeded, or edited by hand) is never overwritten.
 * There is no currencies table.
 */
@Service
@Slf4j
@RequiredArgsConstructor
public class GatewayDirectorySyncService {

    // Short timeouts: this runs at startup, a slow gateway must not hold the app back
    private final RestTemplate restTemplate = buildRestTemplate();
    private final GatewayCountriesRepository gatewayCountriesRepository;

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

    /**
     * Countries to probe; configurable so coverage can grow without a redeploy.
     */
    @Value("${app.gateway.countries:GH,NG,KE,TZ,UG,RW,ZA,CI,SN,CM}")
    String configuredCountries;

    // Static reference metadata: gateways prove *support*; this map supplies display names, dial codes
    // and the starting default currency for a country that is not in the table yet.
    private static final Map<String, CountryMeta> COUNTRY_META = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);

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
    }

    private static RestTemplate buildRestTemplate() {
        org.springframework.http.client.SimpleClientHttpRequestFactory factory = new org.springframework.http.client.SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(5000);
        factory.setReadTimeout(10000);
        return new RestTemplate(factory);
    }

    private static void register(String code, String name, String iso3, String dial, String region, String curr) {
        COUNTRY_META.put(code, new CountryMeta(name, iso3, dial, region, curr));
    }

    /**
     * Entry point used by the scheduler: probes every configured country
     * against all three gateways and refreshes the country rows.
     * Populated on every boot (cold-start seed, see Schedulers#onStartup) and again daily as part of
     * Schedulers#syncProvidersDaily's unified run - no separate cron here, so this directory refreshes on
     * the same trigger and country list as banks/bill-providers/momo instead
     * of drifting on its own independent schedule.
     */
    @Transactional
    public void refreshGatewayDirectory() {
        final LocalDateTime now = LocalDateTime.now();

        // countryCode -> gateways proving support for it
        Map<String, Set<String>> countryGateways = new TreeMap<>(String.CASE_INSENSITIVE_ORDER);

        for (String raw : configuredCountries.split(",")) {
            String cc = raw.trim();
            if (cc.isEmpty()) continue;
            probePaystack(cc.toUpperCase(), countryGateways);
            probeFlutterwave(cc.toUpperCase(), countryGateways);
            probeOnafriq(cc.toUpperCase(), countryGateways);
        }

        // Cold-start fallback: gateways unreachable (no keys offline / network)
        // - seed the configured launch corridors marked 'bootstrap' so
        // registration and wallet creation still work until the next run.
        if (countryGateways.isEmpty()) {
            for (String raw : configuredCountries.split(",")) {
                String cc = raw.trim().toUpperCase();
                if (!cc.isEmpty()) {
                    countryGateways.computeIfAbsent(cc, k -> new LinkedHashSet<>()).add("bootstrap");
                }
            }
        }

        for (Map.Entry<String, Set<String>> e : countryGateways.entrySet()) {
            upsertCountry(e.getKey().toUpperCase(), String.join(",", e.getValue()).toLowerCase(), now);
        }
        log.info("Gateway directory refreshed: {} countries", countryGateways.size());
    }

    // ------------------------------------------------------------------
    // Gateway probes
    // ------------------------------------------------------------------

    private void probePaystack(String cc, Map<String, Set<String>> countryGateways) {
        String url = paystackBaseUrl + "/bank?country=" + cc;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + paystackSk);
        try {
            ResponseEntity<PaystackBankResponseDTO> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), PaystackBankResponseDTO.class);
            if (response.getBody() != null && Boolean.TRUE.equals(response.getBody().status())) {
                countryGateways.computeIfAbsent(cc, k -> new LinkedHashSet<>()).add("paystack");
            }
        } catch (Exception e) {
            log.warn("Paystack probe failed for {}: {}", cc, e.getMessage());
        }
    }

    private void probeFlutterwave(String cc, Map<String, Set<String>> countryGateways) {
        String url = flutterwaveBaseUrl + "/banks/" + cc;
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + flutterwaveSk);
        try {
            ResponseEntity<FlutterwaveBankResponseDTO> response = restTemplate.exchange(
                    url, HttpMethod.GET, new HttpEntity<>(headers), FlutterwaveBankResponseDTO.class);
            if (response.getBody() != null && "success".equalsIgnoreCase(response.getBody().status())) {
                countryGateways.computeIfAbsent(cc, k -> new LinkedHashSet<>()).add("flutterwave");
            }
        } catch (Exception e) {
            log.warn("Flutterwave probe failed for {}: {}", cc, e.getMessage());
        }
    }

    private void probeOnafriq(String cc, Map<String, Set<String>> countryGateways) {
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

    private void upsertCountry(String countryCode, String gateways, LocalDateTime now) {
        CountriesModel row = gatewayCountriesRepository.findById(countryCode)
                .orElseGet(() -> {
                    CountriesModel fresh = new CountriesModel();
                    fresh.setCountryCode(countryCode);
                    fresh.setCreatedAt(now);
                    return fresh;
                });
        CountryMeta meta = COUNTRY_META.get(countryCode);
        row.setCountryName(meta != null ? meta.name() : countryCode);
        row.setIso3Code(meta != null ? meta.iso3() : countryCode);
        row.setDialCode(meta != null ? meta.dial() : "");
        row.setRegion(meta != null ? meta.region() : "");
        // default_currency decides which currency payments use. A value already in the table (seeded or edited
        // by hand) is kept; the built-in one only fills a brand-new or blank row.
        if (row.getDefaultCurrency() == null || row.getDefaultCurrency().isBlank()) {
            row.setDefaultCurrency(meta != null ? meta.defaultCurrency() : "USD");
        }
        row.setGateways(gateways);
        row.setDefault("GH".equalsIgnoreCase(countryCode));
        row.setActive(true);
        row.setUpdatedAt(now);
        gatewayCountriesRepository.save(row);
    }

    // ------------------------------------------------------------------
    // Static reference metadata records
    // ------------------------------------------------------------------

    private record CountryMeta(String name, String iso3, String dial, String region, String defaultCurrency) {
    }
}
