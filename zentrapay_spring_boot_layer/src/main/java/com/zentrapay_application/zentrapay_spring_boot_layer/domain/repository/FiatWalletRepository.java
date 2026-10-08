package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatWalletModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FiatWalletRepository extends JpaRepository<FiatWalletModel, UUID> {
    Optional<FiatWalletModel> findByUserId(@Param("userId") UUID userId);
//    CHECKING IF THE USER WALLET EXIST FOR PAYMENT
    boolean existsByUserId(@Param("userId") UUID userId);
    Optional<FiatWalletModel> getWalletByUserId(@Param("userId") UUID userId);
    @Query("SELECT w.walletId FROM FiatWalletModel w WHERE w.userId = :userId")
    Optional<UUID> getWalletIdByUserId(@Param("userId") UUID userId);
//   gettting userId using the wallet id
    @Query("SELECT w.userId FROM FiatWalletModel w WHERE w.walletId = :walletId")
    Optional<UUID> getUserIdByWalletId(@Param("walletId") UUID walletId);
//    getting all the wallet ids user list of user ids
    @Query("SELECT w.walletId FROM FiatWalletModel w WHERE w.userId IN :userIds")
    List<UUID> getWalletIdsByUserIds(@Param("userIds") List<UUID> userIds);
}

