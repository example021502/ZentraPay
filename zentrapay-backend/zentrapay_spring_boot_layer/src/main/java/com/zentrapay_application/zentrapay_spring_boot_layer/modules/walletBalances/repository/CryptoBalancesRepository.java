package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository;

<<<<<<< HEAD
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.CryptoBalancesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
    public interface CryptoBalancesRepository extends JpaRepository<CryptoBalancesModel, Long> {
        List<CryptoBalancesModel> findByUserId(String userId);
=======
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.WalletBalancesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
    public interface FiatBalancesRepository extends JpaRepository<WalletBalancesModel, Long> {
        boolean findByUserId(String userId);
>>>>>>> update
    }
