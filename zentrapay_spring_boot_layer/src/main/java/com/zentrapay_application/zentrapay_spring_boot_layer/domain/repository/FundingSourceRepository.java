package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.LinkedFundingSource;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.FundingSourceSearchDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface LinkedFundingSourceRepository extends JpaRepository<LinkedFundingSource, UUID> {
    @Query("SELECT f FROM LinkedFundingSource f WHERE f.sourceId In (:sourceIds)")
    List<LinkedFundingSource> findBySourceIds(List<UUID> sourceIds);

    // Searches funding sources by query while ensuring it only returns sources belonging to the user
    @Query("""
            SELECT f FROM LinkedFundingSource f
            WHERE (
                LOWER(f.sourceName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR f.accountIdentifier LIKE CONCAT('%', :query, '%')
                OR f.sourceType LIKE CONCAT('%', :query, '%')
            )
            AND f.countryCode = :countryCode AND f.sourceId IN (:sourceIds)
            """)
    List<FundingSourceSearchDTO> searchByQueryAndCountryCode(
            @Param("query") String query,
            List<UUID> sourceIds,
            String countryCode
    );
}