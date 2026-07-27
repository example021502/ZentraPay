package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.FiatBalancesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface FiatBalancesRepository extends JpaRepository<FiatBalancesModel, Long> {
    List<FiatBalancesModel> findByUserId(String userId);
    List<FiatBalancesModel> findByUserIdAndCurrencyCode(String userId, String currencyCode);
    Optional<FiatBalancesModel> findByUserIdAndCurrency(UUID userId, String currency);
}
