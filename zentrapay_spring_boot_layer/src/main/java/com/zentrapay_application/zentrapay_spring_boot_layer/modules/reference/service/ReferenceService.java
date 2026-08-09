package com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.CountryRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.CurrencyRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository.ProviderCategoryRepository;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.dto.CountryDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.dto.CurrencyDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.reference.dto.ProviderCategoryDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Read-only reference/lookup data — countries, currencies, provider categories.
 * All public, all "load once" client-side (see API_CONTRACT.md §2).
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReferenceService {

    private final CountryRepository countryRepository;
    private final CurrencyRepository currencyRepository;
    private final ProviderCategoryRepository providerCategoryRepository;

    public List<CountryDTO> getCountries() {
        return countryRepository.findByIsActiveTrue().stream()
                .map(c -> new CountryDTO(
                        c.getCountryId(),
                        c.getAccountId(),
                        c.getCountryIsoCode(),
                        c.getIsActive(),
                        c.getIsDefault()))
                .toList();
    }

    public List<CurrencyDTO> getCurrencies() {
        return currencyRepository.findByIsActiveTrue().stream()
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
}
