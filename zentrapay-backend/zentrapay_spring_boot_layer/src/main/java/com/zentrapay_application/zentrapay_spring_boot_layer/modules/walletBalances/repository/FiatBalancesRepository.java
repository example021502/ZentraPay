package com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.users.model.usersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.walletBalances.model.WalletBalancesModel;
import jakarta.validation.constraints.Email;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
    public interface WalletBalancesRepository extends JpaRepository<WalletBalancesModel, Long> {
        boolean findByUserId(String userId);
    }
