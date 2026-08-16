package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatWalletModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface FiatWalletRepository extends JpaRepository<FiatWalletModel, UUID> {
    Optional<FiatWalletModel> findByUserId(@Param("userId") UUID userId);
    boolean existsByUserId(@Param("userId") UUID userId);
}
