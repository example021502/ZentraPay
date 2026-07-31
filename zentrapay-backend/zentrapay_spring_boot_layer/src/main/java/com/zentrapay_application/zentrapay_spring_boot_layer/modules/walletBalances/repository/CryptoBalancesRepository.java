package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.CryptoBalancesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
    public interface CryptoBalancesRepository extends JpaRepository<CryptoBalancesModel, String> {
        List<CryptoBalancesModel> findByUserId(String userId);
    }
