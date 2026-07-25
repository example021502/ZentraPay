package com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.supportedCurrencyAccounts.model.SupportedCurrenciesAccountsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface SupportedCurrenciesAccountsRepository extends JpaRepository<SupportedCurrenciesAccountsModel, Long> {
    List<SupportedCurrenciesAccountsModel> findByIsActive(boolean isActive);
}
