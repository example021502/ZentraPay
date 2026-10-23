package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.BanksModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BanksRepository extends JpaRepository<BanksModel, UUID> {
    @Query("SELECT b FROM BanksModel b WHERE b.bankId IN (:bankIds)")
    List<BanksModel> getAccountsByBanksIds(@Param("bankIds") List<UUID> bankIds);

    //    ================= GETTING THE BANK ACCOUNT FOR PAYMENT
    @Query("SELECT b FROM BanksModel b WHERE b.bankId = :bankId AND LOWER(b.bankName) = :bankName AND LOWER(b.code) = :bankCode")
    Optional<BanksModel> getBankByIdNameAndCode(@Param("bankId") UUID bankId, @Param("bankName") String bankName, @Param("bankCode") String bankCode);

    // Payouts: the picked bank, found by its code
    Optional<BanksModel> findFirstByCodeIgnoreCaseAndCountryCodeIgnoreCase(String code, String countryCode);

    // Payouts: the same bank in another gateway's catalogue, found by name
    Optional<BanksModel> findFirstByGatewayIgnoreCaseAndCountryCodeIgnoreCaseAndBankNameIgnoreCase(String gateway, String countryCode, String bankName);

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
            AND LOWER(b.countryCode) = :countryCode AND b.active = true
            """)
    List<BanksModel> getMatchedBanks(
            @Param("query") String query,
            @Param("countryCode") String countryCode
    );

    @Query("""
            SELECT b FROM BanksModel b
            WHERE b.bankId = :receiverId
            AND b.active = true
            AND LOWER(b.countryCode)= :countryCode
            """)
    Optional<BanksModel> getContactByQueryAndCountryCode(
            @Param("receiverId") UUID receiverId,
            @Param("countryCode") String countryCode
    );
}
