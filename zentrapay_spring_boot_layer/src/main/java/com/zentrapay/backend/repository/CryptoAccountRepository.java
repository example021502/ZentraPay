package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.CryptoAccountModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface CryptoAccountRepository extends JpaRepository<CryptoAccountModel, UUID> {
    List<CryptoAccountModel> findByWalletId(@Param("walletId") UUID walletId);
}
