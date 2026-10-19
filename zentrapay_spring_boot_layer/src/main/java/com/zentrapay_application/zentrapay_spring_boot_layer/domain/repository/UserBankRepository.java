package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserBankModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserBankRepository extends JpaRepository<UserBankModel, UUID> {
    @Query("SELECT ub.bankId FROM UserBankModel ub WHERE ub.userId = :userId")
    List<UUID> getBankIdsByUserId(@Param("userId") UUID userId);

    @Query("SELECT ub.balance FROM UserBankModel ub WHERE ub.userId = :userId AND ub.bankId = :bankId")
    UserBankModel getBalanceByUserIdAndBankId(@Param("userId") UUID userId, @Param("bankId") UUID bankId);

    /** Return every linked row for a user so the UI can render the horizontal strip. */
    List<UserBankModel> findByUserId(UUID userId);

    /**
     * Flip the user's primary account off before a new one is set.
     *
     * NOTE: this MUST be an UPDATE, not a DELETE — an earlier revision of this
     * query deleted the primary row itself, which silently unlinked the bank
     * every time a user promoted another account to primary.
     */
    @Modifying
    @Query(value = "UPDATE user_bank SET is_primary = false WHERE user_id = :userId AND is_primary = true", nativeQuery = true)
    void clearPrimaryForUser(@Param("userId") UUID userId);

    /** Used to reject linking the same bank twice. */
    Optional<UserBankModel> findByUserIdAndBankId(UUID userId, UUID bankId);
}
