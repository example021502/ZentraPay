package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.VirtualAccountModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface VirtualAccountRepository extends JpaRepository<VirtualAccountModel, UUID> {
    @Query("SELECT v.merchantReference FROM VirtualAccountsModel v WHERE v.userId = :userId")
    String getMerchantReferenceByUserId(@Param("userId") UUID userID);

    @Query("SELECT v.balance FROM VirtualAccountsModel v WHERE v.userId = :userId")
    Optional<BigDecimal> getBalanceByUserId(@Param("userId") UUID userID);

    List<VirtualAccountModel> getAccountsByUserId(@Param("userId") UUID userID);

    @Query("SELECT a.currencyCode FROM VirtualAccountsModel a WHERE a.userId =:userId")
    List<String> getCurrencyCodesByUserId(@Param("userId") UUID userId);

    // Spring Data automatically generates an optimized EXISTS query from the method name
    boolean existsByMerchantReferenceAndCurrencyCode(String merchantReference, String currencyCode);

    boolean existsByUserIdAndCurrencyCode(UUID userId, String currencyCode);

    @Query("SELECT a FROM VirtualAccountModel a WHERE a.userId =:userId AND (a.currencyCode =:currencyCode OR a.merchantReference =:merchantReference)")
    Optional<VirtualAccountModel> getAccountByUserIdAndCurrencyCodeOrMerchantReference(UUID userId, String currencyCode, String merchantReference);
}
