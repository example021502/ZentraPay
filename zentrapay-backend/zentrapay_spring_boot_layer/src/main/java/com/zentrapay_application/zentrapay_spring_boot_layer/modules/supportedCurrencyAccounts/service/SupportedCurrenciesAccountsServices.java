package com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.dto.SupportedCurrenciesAccountsResponseDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.model.SupportedCurrenciesAccountsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.repository.SupportedCurrenciesAccountsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class SupportedCurrenciesAccountsServices {
    private final SupportedCurrenciesAccountsRepository supportedCurrenciesAccountsRepository;

    // Fixed return type to match controller and properly handle repository call
    public SupportedCurrenciesAccountsResponseDTO getSupportedCurrencyAccounts() {
        // Fetch list of active supported currencies from gateway_accounts table
        List<SupportedCurrenciesAccountsModel> activeCurrencies = supportedCurrenciesAccountsRepository.findByIsActive(true);

        return new SupportedCurrenciesAccountsResponseDTO(activeCurrencies);
    }
}