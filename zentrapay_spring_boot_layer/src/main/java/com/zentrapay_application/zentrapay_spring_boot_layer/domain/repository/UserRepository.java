package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.*;
import com.zentrapay_application.zentrapay_spring_boot_layer.domain.utils.Datatypes;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.UserSearchDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<UserModel, UUID> {
//    get user country code for fetching supported currencies for user's country
    boolean existsByEmailOrPhoneNumber(@Param("email") String email, @Param("phoneNumber") String phoneNumber);
//    check if user exist in the database by email or phone number for loging in
    @Query("SELECT u FROM UserModel u WHERE u.email = :email OR u.phoneNumber = :phoneNumber")
    Optional<UserModel> findByEmailOrPhoneNumber(@Param("email") String email, @Param("phoneNumber") String phoneNumber);
//    checking if the email exist for account creation
    boolean existsByEmail(String email);
//    checking if phone number exist for account creation
    boolean existsByPhoneNumber(String phoneNumber);

    //  getting the user details ======
    Optional<UserModel> getUserByUserId(@Param("userId") UUID userId);

    //  getting the users matched contacts
    @Query("""
    SELECT new com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.UserSearchDTO(
        u.userId,
        u.countryCode,
        u.email,
        u.firstName,
        u.lastName,
        u.phoneNumber,
        fa.zentag,
        u.userType
    )
    FROM FiatAccountModel fa
    JOIN FiatWalletModel w ON fa.walletId = w.walletId
    JOIN UserModel u ON w.userId = u.userId
    WHERE (LOWER(u.firstName) LIKE LOWER(CONCAT('%', :query, '%'))
       OR LOWER(u.lastName) LIKE LOWER(CONCAT('%', :query, '%'))
       OR LOWER(fa.zentag) LIKE LOWER(CONCAT('%', :query, '%'))
       OR u.phoneNumber LIKE CONCAT('%', :query, '%'))
      AND LOWER(u.countryCode) = LOWER(:countryCode)
      AND u.userId != :userId
""")
    List<UserSearchDTO> searchByQueryAndCountryCode(
            @Param("query") String query,
            @Param("countryCode") String countryCode,
            @Param("userId") UUID userId
    );

    @Query("""
            SELECT new com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.UserSearchDTO(
                    u.userId,
                    u.countryCode,
                    u.email,
                    u.firstName,
                    u.lastName,
                    u.phoneNumber,
                    fa.zentag,
                    u.userType
            ) FROM FiatAccountModel fa
            JOIN FiatWalletModel w ON fa.walletId = w.walletId
            JOIN UserModel u ON w.userId = u.userId
            WHERE u.userId = :query
            AND LOWER(u.countryCode) = :countryCode AND u.status = :status
            """)
    Optional<UserSearchDTO> getContactByQueryAndCountryCode(
            @Param("query") UUID query,
            @Param("countryCode") String countryCode,
            @Param("status") Datatypes.UserStatus status
    );

    @Query("SELECT u FROM UserModel u WHERE u.phoneNumber = :phoneNumber")
    Optional<UserModel> findByPhoneNumber(@Param("phoneNumber") String phoneNumber);
}
