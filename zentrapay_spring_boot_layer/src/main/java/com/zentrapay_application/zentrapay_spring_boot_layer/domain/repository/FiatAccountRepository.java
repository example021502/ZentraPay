package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.FiatAccountModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface FiatAccountRepository extends JpaRepository<FiatAccountModel, UUID> {
    List<FiatAccountModel> findByWalletId(@Param("walletId") UUID walletId);

//  GETTING THE ACCOUNT USING WALLET ID FOR MAKING A PAYMENT
    Optional<FiatAccountModel> getWalletByWalletIdAndCurrencyCode(@Param("walletId") UUID walletId, @Param("currencyCode") String currencyCode);
//  CHECKING IF THE WALLET EXIST FOR WALLET CURRENCY ACCOUNT CREATION
    boolean existsByWalletIdAndCurrencyCode(@Param("walletId") UUID walletId, @Param("currencyCode") String currencyCode);

//  GETTING USER FIAT ACCOUNT CURRENCIES FOR GETTING SUPPORTED CURRENCIES EXCLUDING THEM
    @Query("SELECT a.currencyCode FROM FiatAccountModel a WHERE a.walletId = :walletId")
    List<String> getAccountsCurrenciesByWalletId(@Param("walletId") UUID walletId);

//  not decorative, or this would debit every currency this wallet holds.
    @Modifying
    @Query("UPDATE FiatAccountModel w SET w.balance = w.balance - :amount WHERE w.walletId = :walletId AND w.currencyCode = :currencyCode AND w.balance >= :amount")
    int debit(@Param("walletId") UUID walletId, @Param("amount") BigDecimal amount, @Param("currencyCode") String currencyCode);

//  CREDIT OPERATION FOR WALLET TO WALLET TRANSFER WITHIN THE SAME COUNTRY
    @Modifying
    @Query("UPDATE FiatAccountModel w SET w.balance = w.balance + :amount WHERE w.walletId = :walletId AND w.currencyCode = :currencyCode")
    int credit(@Param("walletId") UUID walletId, @Param("amount") BigDecimal amount,@Param("currencyCode") String currencyCode);
}
