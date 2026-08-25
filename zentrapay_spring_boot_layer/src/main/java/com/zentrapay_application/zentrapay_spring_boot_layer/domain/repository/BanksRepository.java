package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.BanksModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BanksRepository extends JpaRepository<BanksModel, UUID> {
    @Query("SELECT b FROM BanksModel b WHERE b.bankId IN (:bankIds)")
    List<BanksModel> getAccountsByBanksIds(@Param("bankIds") List<UUID> bankIds);

    // Used by the provider sync job to upsert rather than duplicate rows on
    // every scheduled run.
    Optional<BanksModel> findByCodeAndGatewayAndCountryCode(String code, String gateway, String countryCode);

    // Searches funding sources by query while ensuring it only returns sources belonging to the user
    @Query("""
            SELECT b FROM BanksModel b
            WHERE (
                LOWER(b.bankName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(b.countryCode) LIKE CONCAT('%', :query, '%')
                OR LOWER(b.gateway) LIKE CONCAT('%', :query, '%')
                OR LOWER(b.code) LIKE CONCAT('%', :query, '%')
            )
            AND LOWER(b.countryCode) = :countryCode AND LOWER(b.status) = "active"
            """)
    List<BanksModel> getMatchedBanks(
            @Param("query") String query,
            @Param("countryCode") String countryCode
    );

    @Query("""
            SELECT b FROM BanksModel b
            WHERE b.bankId = :query
            AND LOWER(b.countryCode)= :countryCode
            """)
    Optional<BanksModel> getContactByQueryAndCountryCode(
            @Param("query") UUID query,
            @Param("countryCode") String countryCode
    );
}
