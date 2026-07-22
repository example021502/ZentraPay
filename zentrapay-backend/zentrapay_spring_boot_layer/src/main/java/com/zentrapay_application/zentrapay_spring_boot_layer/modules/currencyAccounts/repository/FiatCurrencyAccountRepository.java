package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model.FiatAccountModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FiatCurrencyAccountRepository extends JpaRepository<FiatAccountModel, String> {
    List<FiatAccountModel> findByUserIdAndCurrencyCode(String userId, String currencyCode);
}