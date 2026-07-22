package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.WalletBalancesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
    public interface FiatBalancesRepository extends JpaRepository<WalletBalancesModel, Long> {
        boolean findByUserId(String userId);
    }
