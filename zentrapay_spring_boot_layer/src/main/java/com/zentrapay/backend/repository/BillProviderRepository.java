package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.BillProviderModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BillProviderRepository extends JpaRepository<BillProviderModel, UUID> {

    List<BillProviderModel> getAllBillProvidersByCountryCode(@Param("countryCode") String countryCode);

    /**
     * Country-filtered directory used by GET /api/bill-providers — active
     * rows only, ordered alphabetically. Lower-cased compare because
     * seeded rows and the JWT's country disagree on case ('GH' vs 'gh').
     */
    @Query("""
            SELECT p FROM BillProviderModel p
            WHERE LOWER(p.countryCode) = :countryCode AND p.active = true
            ORDER BY p.billerName
            """)
    List<BillProviderModel> findActiveByCountryCode(@Param("countryCode") String countryCode);

    // Used by the provider sync job to upsert instead of duplicating rows.
    // biller_code is NOT unique (multi-gateway rows) — callers that need a
    // single row must narrow by gateway or take the first match.
    List<BillProviderModel> findByBillerCode(String billerCode);

    // Exact row for a (biller, gateway) pair — the multi-gateway upsert key.
    Optional<BillProviderModel> findByBillerCodeAndGateway(String billerCode, String gateway);

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
            WHERE p.providerId = :receiverId
            AND LOWER(p.countryCode) = :countryCode AND p.active = true
            """)
    Optional<BillProviderModel> getContactByQueryAndCountryCode(
            @Param("receiverId") UUID receiverId,
            @Param("countryCode") String countryCode
    );
}
