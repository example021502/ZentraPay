package com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.dto;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.model.SupportedCurrenciesAccountsModel;

import java.util.List;

public record SupportedCurrenciesAccountsResponseDTO(
        List<SupportedCurrenciesAccountsModel> accounts
) {}
