package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository;

<<<<<<< HEAD
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.FiatBalancesModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
    public interface FiatBalancesRepository extends JpaRepository<FiatBalancesModel, Long> {
        List<FiatBalancesModel> findByUserId(String userId);
=======
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.usersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.WalletBalancesModel;
import jakarta.validation.constraints.Email;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
    public interface WalletBalancesRepository extends JpaRepository<WalletBalancesModel, Long> {
        boolean findByUserId(String userId);
>>>>>>> update
    }
