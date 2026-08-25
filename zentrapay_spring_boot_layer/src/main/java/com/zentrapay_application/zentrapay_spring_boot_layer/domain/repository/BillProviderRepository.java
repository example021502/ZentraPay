package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BillProviderModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BillProviderRepository extends JpaRepository<BillProviderModel, UUID> {

    List<BillProviderModel> getAllBillProvidersByCountryCode(@Param("countryCode") String countryCode);

    // Used by the provider sync job to upsert instead of duplicating rows.
    Optional<BillProviderModel> findByBillerCode(String billerCode);

    @Query("""
            SELECT p FROM BillProviderModel p
            WHERE (
                LOWER(p.billerName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(p.billerCode) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(p.categoryCode) LIKE CONCAT('%', :query, '%')
            )
            AND LOWER(p.countryCode) = :countryCode AND p.active = true
            """)
    List<BillProviderModel> getMatchedBillProviders(
            @Param("query") String query,
            @Param("countryCode") String countryCode
    );

    @Query("""
            SELECT p FROM BillProviderModel p
            WHERE p.providerId = :query
            AND LOWER(p.countryCode) = :countryCode AND p.active = true
            """)
    Optional<BillProviderModel> getContactByQueryAndCountryCode(
            @Param("query") UUID query,
            @Param("countryCode") String countryCode
    );
}
