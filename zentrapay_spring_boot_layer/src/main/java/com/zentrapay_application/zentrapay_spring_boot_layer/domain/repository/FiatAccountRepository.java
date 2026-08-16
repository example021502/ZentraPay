package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatAccountModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

public interface FiatAccountRepository extends JpaRepository<FiatAccountModel, UUID> {
    List<FiatAccountModel> findByWalletId(@Param("walletId") UUID walletId);
//  CHECKING IF THE WALLET EXIST FOR WALLET CURRENCY ACCOUNT CREATION
    boolean existsByWalletIdAndCurrencyCode(@Param("walletId") UUID walletId, @Param("currencyCode") String currencyCode);
//  DEBIT OPERATION FOR WALLET TO WALLET TRANSFER WITHIN THE SAME COUNTRY
    @Modifying
    @Query("UPDATE FiatAccountModel w SET w.balance = w.balance - :amount WHERE w.walletId = :walletId AND w.balance >= :amount")
    int debit(@Param("walletId") UUID walletId, @Param("amount") BigDecimal amount, @Param("currencyCode") String currencyCode);

//  CREDIT OPERATION FOR WALLET TO WALLET TRANSFER WITHIN THE SAME COUNTRY
    @Modifying
    @Query("UPDATE FiatAccountModel w SET w.balance = w.balance + :amount WHERE w.walletId = :walletId")
    int credit(@Param("walletId") UUID walletId, @Param("amount") BigDecimal amount,@Param("currencyCode") String currencyCode);
}
