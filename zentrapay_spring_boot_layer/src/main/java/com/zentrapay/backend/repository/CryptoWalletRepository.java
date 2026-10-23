package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.CryptoWalletModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface CryptoWalletRepository extends JpaRepository<CryptoWalletModel, UUID> {
    Optional<CryptoWalletModel> findByUserId(@Param("userId") UUID userId);
    boolean existsByUserId(@Param("userId") UUID userId);
}
