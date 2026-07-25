package com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.model.PaymentsUsersModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.payments.model.UsersWalletsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.UUID;

@Repository
public interface UserWalletsRepository extends JpaRepository<UsersWalletsModel, Long> {

    @Query("SELECT u FROM PaymentsUsersModel u WHERE u.userId = :userId OR u.phoneNumber = :phoneNumber OR u.zentag = :zentag")
    PaymentsUsersModel existsByUserIdOrPhoneNumber(
            @Param("userId") UUID userId,
            @Param("phoneNumber") String phoneNumber,
            @Param("zentag") String zentag
    );

    @Query("SELECT w FROM UsersWalletsModel w WHERE w.userId = :userId AND w.currencyCode = :currencyCode")
    UsersWalletsModel getWalletByUserIdAndCurrencyCode(
            @Param("userId") UUID userId,
            @Param("currencyCode") String currencyCode
    );

    @Modifying
    @Query("UPDATE UsersWalletsModel w SET w.balance = w.balance - :amount WHERE w.userId = :userId")
    int debit(@Param("userId") UUID userId, @Param("currencyCode") String currencyCode, @Param("amount") BigDecimal amount);

    @Modifying
    @Query("UPDATE UsersWalletsModel w SET w.balance = w.balance + :amount WHERE w.userId = :userId")
    int credit(@Param("userId") UUID userId, @Param("currencyCode") String currencyCode, @Param("amount") BigDecimal amount);
}