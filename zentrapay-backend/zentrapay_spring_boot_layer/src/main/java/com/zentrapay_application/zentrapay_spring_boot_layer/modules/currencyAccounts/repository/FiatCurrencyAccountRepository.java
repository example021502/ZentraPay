package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model.FiatCurrencyAccountModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface FiatCurrencyAccountRepository extends JpaRepository<FiatCurrencyAccountModel, UUID> {
    List<FiatCurrencyAccountModel> findByWalletIdAndCurrencyCode(UUID wallet_id, String currencyCode);
}