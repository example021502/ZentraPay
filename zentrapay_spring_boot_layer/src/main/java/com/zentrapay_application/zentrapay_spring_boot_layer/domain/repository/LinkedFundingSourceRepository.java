package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.LinkedFundingSource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface LinkedFundingSourceRepository extends JpaRepository<LinkedFundingSource, UUID> {
    List<LinkedFundingSource> findByUserId(UUID userId);

    // Searches funding sources by query while ensuring it only returns sources belonging to the user
    @Query("""
            SELECT f FROM LinkedFundingSource f
            WHERE (
                LOWER(f.sourceName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR f.accountIdentifier LIKE CONCAT('%', :query, '%') 
                OR f.sourceType LIKE CONCAT('%', :query, '%')
            )
            AND f.userId = :userId
            """)
    List<LinkedFundingSource> searchByQuery(
            @Param("query") String query,
            @Param("userId") UUID userId
    );
}