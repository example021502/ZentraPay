package com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.model.BillProvider;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface BillProviderRepository extends JpaRepository<BillProvider, UUID> {
    List<BillProvider> findByCountryCode(String countryCode);

    List<BillProvider> findByCategoryCode(String categoryCode);

    List<BillProvider> findByCountryCodeAndCategoryCode(String countryCode, String categoryCode);

    Optional<BillProvider> findByBillerCode(String billerCode);

    // Searches bill providers by query while excluding a specific provider ID (e.g., if needed)
    @Query("""
            SELECT p FROM BillProvider p
            WHERE p.active = True
            AND (
                LOWER(p.billerName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(p.categoryCode) LIKE LOWER(CONCAT('%', :query, '%'))
            )
            AND p.providerId != :excludeId
            """)
    List<BillProvider> searchByQuery(
            @Param("query") String query,
            @Param("excludeId") UUID excludeId
    );
}