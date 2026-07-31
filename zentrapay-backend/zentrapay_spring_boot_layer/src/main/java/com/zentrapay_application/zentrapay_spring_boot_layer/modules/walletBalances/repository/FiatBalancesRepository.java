package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.FiatBalancesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FiatBalancesRepository extends JpaRepository<FiatBalancesModel, String> {
    List<FiatBalancesModel> findByUserId(UUID userId);
    List<FiatBalancesModel> findByUserIdAndCurrencyCode(UUID userId, String currencyCode);
    Optional<FiatBalancesModel> findByUserIdAndCurrency(UUID userId, String currency);
}
