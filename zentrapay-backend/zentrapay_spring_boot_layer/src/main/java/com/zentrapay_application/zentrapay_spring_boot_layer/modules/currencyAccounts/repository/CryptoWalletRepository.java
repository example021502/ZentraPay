package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model.CryptoWallet;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface CryptoWalletRepository extends JpaRepository<CryptoWallet, String> {
    Optional<CryptoWallet> findByUserId(String userId);
    boolean existsByUserId(String userId);
}