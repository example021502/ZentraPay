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

    List<VirtualAccountModel> getAccountByUserId(@Param("userId") UUID userID);
}
