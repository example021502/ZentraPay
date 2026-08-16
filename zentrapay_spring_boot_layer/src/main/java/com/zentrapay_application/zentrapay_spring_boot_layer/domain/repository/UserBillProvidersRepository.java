package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserBillProviderModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

/**
 * The {@code user_bill_providers} table no longer exists in the Flyway schema,
 * so the "bill providers this user has paid with" set is derived from their
 * {@code bill_payments} rows (which carry both {@code user_id} and
 * {@code provider_id}) instead.
 */
public interface UserBillProvidersRepository extends JpaRepository<UserBillProviderModel, UUID> {
    @Query("SELECT DISTINCT b.providerId FROM UserBillProviderModel b WHERE b.userId = :userId")
    List<UUID> getUserBillProvidersIdsByUserId(@Param("userId") UUID userId);
}