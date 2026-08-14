package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<UserModel, UUID> {

    // Resolves a login identifier (either email or phone number). The derived method
    // name "findByEmailOrPhoneNumber" cannot be reliably parsed by Spring Data, so an
    // explicit query is used.
    @Query("SELECT u FROM UserModel u WHERE u.email = :email OR u.phoneNumber = :phoneNumber")
    Optional<UserModel> findByEmailOrPhoneNumber(@Param("email") String email, @Param("phoneNumber") String phoneNumber);


    boolean existsByEmail(String email);

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
                OR LOWER(u.zentag) LIKE LOWER(CONCAT('%', :query, '%'))
            )
            AND u.countryCode = :countryCode
            """)
    List<UserModel> searchByQueryAndCountryCode(
            @Param("query") String query,
            @Param("countryCode") String countryCode
    );
}
