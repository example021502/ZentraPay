package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BillProviderModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface BillProviderRepository extends JpaRepository<BillProviderModel, UUID> {

    @Query("SELECT p FROM BillProviderModel p WHERE p.countryCode = :countryCode")
    List<BillProviderModel> getAllBillProviders(@Param("countryCode") String countryCode);

    @Query("""
            SELECT p FROM BillProviderModel p
            WHERE (
                LOWER(p.billerName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(p.billerCode) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(p.categoryCode) LIKE CONCAT('%', :query, '%')
            )
            AND p.providerId IN (:providerIds) AND p.countryCode = :countryCode
            """)
    List<BillProviderModel> getBillProvidersByQueryCountryCodeAndProviderIds(
            @Param("query") String query,
            @Param("countryCode") String countryCode,
            @Param("providerIds") List<UUID> providerIds
    );
}
