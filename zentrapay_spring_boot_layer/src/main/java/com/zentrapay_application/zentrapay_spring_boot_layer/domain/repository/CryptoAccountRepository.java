package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.CryptoAccountModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.wallets.dtos.CryptoAccountDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface CryptoAccountRepository extends JpaRepository<CryptoAccountModel, UUID> {
    List<CryptoAccountDTO> findByWalletId(@Param("walletId") UUID walletId);
}
