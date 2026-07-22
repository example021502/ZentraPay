package com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.currencyAccounts.model.CryptoAccountModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface CryptoCurrencyAccountRepository extends JpaRepository<CryptoAccountModel, String> {
    List<CryptoAccountModel> findByUserId(String userId);
    Optional<CryptoAccountModel> findByWalletAddress(String walletAddress);
    Optional<CryptoAccountModel> findByUserIdAndCurrencyCode(String userId, String currencyCode);
    boolean existsByWalletAddress(String walletAddress);
}