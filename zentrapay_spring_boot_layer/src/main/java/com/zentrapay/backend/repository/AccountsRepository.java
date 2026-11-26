package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.AccountsModel;
import com.zentrapay.backend.service.common.Datatypes;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface AccountsRepository extends JpaRepository<AccountsModel, UUID> {
    @Query("SELECT a.zentag FROM AccountsModel a WHERE a.userId = :userId AND a.currencyCode =:currencyCode")
    String getMerchantReferenceByUserId(@Param("userId") UUID userId, @Param("currencyCode") String currencyCode);

    @Query("SELECT a.balance FROM AccountsModel a WHERE a.userId = :userId")
    Optional<BigDecimal> getBalanceByUserId(@Param("userId") UUID userId, @Param("currencyCode") String currencyCode);

    @Query("SELECT a.balance FROM AccountsModel a WHERE a.userId = :userId AND a.currencyCode =:currencyCode")
    BigDecimal getBalanceByUserIdAndCurrencyCode(@Param("userId") UUID userId, @Param("currencyCode") String currencyCode);

    List<AccountsModel> getAccountsByUserId(@Param("userId") UUID userID);

    @Query("SELECT a.currencyCode FROM AccountsModel a WHERE a.userId =:userId")
    List<String> getCurrencyCodesByUserId(@Param("userId") UUID userId);

    // Spring Data automatically generates an optimized EXISTS query from the method name
    boolean existsByMerchantReferenceAndCurrencyCode(String merchantReference, String currencyCode);

    boolean existsByUserIdAndCurrencyCode(UUID userId, String currencyCode);

    @Query("SELECT a FROM AccountsModel a WHERE a.userId =:userId AND (a.currencyCode =:currencyCode OR a.merchantReference =:merchantReference)")
    Optional<AccountsModel> getAccountByUserIdAndCurrencyCodeOrMerchantReference(UUID userId, String currencyCode, String merchantReference);

    Optional<AccountsModel> findByUserIdAndCurrencyCodeForUpdate(@Param("userId") UUID userId, @Param("currencyCode") String currencyCode);

    Optional<AccountsModel> findByIdForUpdate(@Param("accountId") UUID accountId);

    Optional<AccountsModel> getAccountByTypeAndCurrencyCodeForUpdate(Datatypes.AccountTypes type, String currencyCode);

    Optional<AccountsModel> gatAccountByLabelIgnoreCaseAndCurrencyCodeIgnoreCaseForUpdate(String label, String currencyCode);
}
