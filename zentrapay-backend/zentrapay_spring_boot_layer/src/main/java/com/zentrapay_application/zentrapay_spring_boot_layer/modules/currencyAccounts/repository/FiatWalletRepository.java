package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model.FiatWallet;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface FiatWalletRepository extends JpaRepository<FiatWallet, String> {
    Optional<FiatWallet> findByUserId(String userId);
    boolean existsByUserId(String userId);
}