package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.CryptoWallet;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CryptoWalletRepository extends JpaRepository<CryptoWallet, UUID> {
    List<CryptoWallet> findByUserId(UUID userId);
    Optional<CryptoWallet> findByWalletAddress(String walletAddress);
    boolean existsByWalletAddress(String walletAddress);
}
