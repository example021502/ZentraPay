package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<UserModel, UUID> {
//    get user country code for fetching supported currencies for user's country
    @Query("SELECT u.countryCode FROM UserModel u WHERE u.userId = :userId")
    Optional<String> getCountryCodeByUserId(@Param("userId") UUID userId);
//    check if user exist in the database by email or phone number for loging in
    @Query("SELECT u FROM UserModel u WHERE u.email = :email OR u.phoneNumber = :phoneNumber")
    Optional<UserModel> findByEmailOrPhoneNumber(@Param("email") String email, @Param("phoneNumber") String phoneNumber);
//    checking if the email exist for account creation
    boolean existsByEmail(String email);
//    checking if phone number exist for account creation
    boolean existsByPhoneNumber(String phoneNumber);

    //  getting the sender details ======
    @Query("SELECT u FROM UserModel u WHERE u.userId = :userId")
    Optional<UserModel> getUserById(@Param("userId") UUID userId);

    //  getting the users matched contacts
    @Query("""
            SELECT u FROM UserModel u
            WHERE (
                LOWER(u.firstName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(u.lastName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(u.phoneNumber) LIKE LOWER(CONCAT('%', :query, '%'))
            )
            AND u.countryCode = :countryCode
            """)
    List<UserModel> searchByQueryAndCountryCode(
            @Param("query") String query,
            @Param("countryCode") String countryCode
    );
}
