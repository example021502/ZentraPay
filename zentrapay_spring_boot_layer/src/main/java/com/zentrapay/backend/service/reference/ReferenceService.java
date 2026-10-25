package com.zentrapay.backend.service.reference;

import lombok.extern.slf4j.Slf4j;
import com.zentrapay.backend.entity.BanksModel;
import com.zentrapay.backend.repository.BanksRepository;
import com.zentrapay.backend.repository.GatewayCountriesRepository;
import com.zentrapay.backend.repository.GatewayCurrenciesRepository;
import com.zentrapay.backend.repository.ProviderCategoryRepository;
import com.zentrapay.backend.dto.reference.BankDTO;
import com.zentrapay.backend.dto.reference.CountryDTO;
import com.zentrapay.backend.dto.reference.CurrencyDTO;
import com.zentrapay.backend.dto.reference.ProviderCategoryDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Read-only reference/lookup data — countries, currencies, provider categories.
 * All public, all "load once" client-side (see API_CONTRACT.md §2).
 *
 * <p>Countries/currencies are served from {@code gateway_countries} /
 * {@code gateway_currencies} — V9__gateway_directory_consolidation retired the
 * old world-reference {@code countries}/{@code currencies} tables, and those
 * directories are kept fresh by the scheduled GatewayDirectorySyncService.
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReferenceService {

    private final GatewayCountriesRepository gatewayCountriesRepository;
    private final GatewayCurrenciesRepository gatewayCurrenciesRepository;
    private final ProviderCategoryRepository providerCategoryRepository;
    private final BanksRepository banksRepository;

    public List<CountryDTO> getCountries() {
        return gatewayCountriesRepository.findByActive(true).stream()
                .map(c -> new CountryDTO(
                        c.getCountryCode(),
                        c.getIso3Code(),
                        c.getCountryName(),
                        c.getDialCode(),
                        c.getCurrencyCode(),
                        c.getRegion()))
                .toList();
    }

    public List<CurrencyDTO> getCurrencies() {
        return gatewayCurrenciesRepository.findByActive(true).stream()
                .map(c -> new CurrencyDTO(
                        c.getCurrencyCode(),
                        c.getCurrencyName(),
                        c.getSymbol(),
                        c.isCrypto(),
                        c.getDecimalPlaces()))
                .toList();
    }

    public List<ProviderCategoryDTO> getProviderCategories() {
        return providerCategoryRepository.findAll().stream()
                .map(c -> new ProviderCategoryDTO(c.getCategoryCode(), c.getCategoryName()))
                .toList();
    }

    /**
     * Bank catalog for the ZBank "link a bank" sheet.
     *
     * @param query    optional case-insensitive filter on name/code/country/gateway.
     * @param country  optional ISO country filter (e.g. {@code "GH"}).
     * @return only active banks, ordered by name so the picker is stable.
     */
    public List<BankDTO> getBanks(String query, String country) {
        // Bank catalogue for the link-a-bank sheet, optionally filtered by text and country
        log.info("Loading banks (query={}, country={})", query, country);
        String filter = query == null ? "" : query.trim();
        boolean hasCountry = country != null && !country.isBlank();
        String countryFilter = hasCountry ? country : null;

        // `getMatchedBanks`' JPQL matches `LOWER(country_code) = :country`, so
        // the country param MUST be lowercase — "GH" never equals "gh", and the
        // query has no wildcard form (passing "%" matched nothing either), which
        // made every search in the link-bank sheet return an empty list. With no
        // country filter we fall back to findAll; the in-memory filters below
        // do the rest (SearchContactsService passes lowercased params too).
        List<BanksModel> source = (filter.isEmpty() || countryFilter == null)
                ? banksRepository.findAll()
                : banksRepository.getMatchedBanks(filter, countryFilter.toLowerCase());

        return source.stream()
                .filter(b -> Boolean.TRUE.equals(b.getActive()))
                .filter(b -> countryFilter == null
                        || countryFilter.equalsIgnoreCase(b.getCountryCode()))
                .filter(b -> filter.isEmpty()
                        || containsIgnoreCase(b.getBankName(), filter)
                        || containsIgnoreCase(b.getCode(), filter)
                        || containsIgnoreCase(b.getCountry(), filter)
                        || containsIgnoreCase(b.getCountryCode(), filter)
                        || containsIgnoreCase(b.getGateway(), filter))
                .sorted(java.util.Comparator.comparing(
                        BanksModel::getBankName,
                        java.util.Comparator.nullsLast(String::compareToIgnoreCase)))
                .map(b -> new BankDTO(
                        b.getBankId(),
                        b.getCode(),
                        b.getBankName(),
                        b.getGateway(),
                        b.getCurrencyCode(),
                        b.getCountryCode(),
                        b.getCountry(),
                        b.getSwiftBic(),
                        b.getRoutingNumber(),
                        b.getType()))
                .toList();
    }

    private static boolean containsIgnoreCase(String value, String needle) {
        return value != null && value.toLowerCase().contains(needle.toLowerCase());
    }
}
