package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BillProviderModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.billProviders.dto.BillProviderDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.BillProviderSearchDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface BillProviderRepository extends JpaRepository<BillProviderModel, UUID> {

    List<BillProviderDTO> getAllBillProvidersByCountryCode(@Param("countryCode") String countryCode);

    @Query("""
            SELECT p FROM BillProviderModel p
            WHERE (
                LOWER(p.billerName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(p.billerCode) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(p.categoryCode) LIKE CONCAT('%', :query, '%')
            )
            AND p.providerId IN (:providerIds) AND p.countryCode = :countryCode
            """)
    List<BillProviderSearchDTO> getBillProvidersByQueryCountryCodeAndProviderIds(
            @Param("query") String query,
            @Param("countryCode") String countryCode,
            @Param("providerIds") List<UUID> providerIds
    );
}
