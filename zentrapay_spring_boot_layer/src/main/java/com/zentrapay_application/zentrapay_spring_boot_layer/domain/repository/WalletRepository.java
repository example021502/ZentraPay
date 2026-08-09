package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.Wallet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface WalletRepository extends JpaRepository<Wallet, UUID> {
    List<Wallet> findByUserId(UUID userId);

    Optional<Wallet> findByUserIdAndCurrencyCode(UUID userId, String currencyCode);

    Optional<Wallet> findByUserIdAndIsDefaultTrue(UUID userId);

    boolean existsByUserIdAndWalletName(UUID userId, String walletName);

    @Modifying
    @Query("UPDATE Wallet w SET w.balance = w.balance - :amount WHERE w.walletId = :walletId AND w.balance >= :amount")
    int debit(@Param("walletId") UUID walletId, @Param("amount") BigDecimal amount);

    @Modifying
    @Query("UPDATE Wallet w SET w.balance = w.balance + :amount WHERE w.walletId = :walletId")
    int credit(@Param("walletId") UUID walletId, @Param("amount") BigDecimal amount);
}
