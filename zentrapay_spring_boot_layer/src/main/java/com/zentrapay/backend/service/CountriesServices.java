package com.zentrapay.backend.service;

import com.zentrapay.backend.entity.CountriesModel;
import com.zentrapay.backend.entity.CurrenciesModel;
import com.zentrapay.backend.entity.UserModel;
import com.zentrapay.backend.repository.CountriesRepository;
import com.zentrapay.backend.repository.CurrenciesRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.annotation.ReadOnlyProperty;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
public class CountriesServices {

    private final CountriesRepository countries;

    public void isCountrySupported(String countryCode) {
        CountriesModel c = findActiveCountry(countryCode);
        if (c == null) {
            throw new RuntimeException("Sorry, Zentrapay is not in your country (" + countryCode + ") yet.");
        }
    }

    public void requireSupportCountry(String countryCode) {
        if (!countries.existsCountryByCode(countryCode)) {
            throw new RuntimeException("Country not supported.");
        }
    }

    private CountriesModel findActiveCountry(String countryCode) {
        if (countryCode == null || countryCode.isBlank()) {
            return null;
        }
        return countries.getCountryByCode(countryCode.trim().toUpperCase(Locale.ROOT));
    }

    public String getCountryNameByCode(String code) {
        return countries.getCountryNameByCode(code);
    }
}
