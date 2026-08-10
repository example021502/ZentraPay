package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.User;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.searchContacts.dto.AppUserSearchDTO;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);

    Optional<User> findByPhoneNumber(String phoneNumber);

    Optional<User> findByZentag(String zentag);

    AppUserSearchDTO getByUserId(UUID userId);

    boolean existsByEmail(String email);

    boolean existsByPhoneNumber(String phoneNumber);

    boolean existsByZentag(String zentag);


    // Searches users by text query while explicitly excluding the current user's ID.
    // Restricted to users sharing the searching user's country — either the same
    // stored countryCode, or (for diaspora users whose profile country lags their
    // actual number) the same phone dial-code prefix.
    @Query("""
            SELECT u FROM User u
            WHERE (
                LOWER(u.firstName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR LOWER(u.lastName) LIKE LOWER(CONCAT('%', :query, '%'))
                OR u.phoneNumber LIKE CONCAT('%', :query, '%')
                OR LOWER(u.zentag) LIKE LOWER(CONCAT('%', :query, '%'))
            )
            AND u.userId != :userId
            AND (
                u.countryCode = :countryCode
                OR u.phoneNumber LIKE CONCAT(:dialCode, '%')
            )
            """)
    List<User> searchByQuery(
            @Param("query") String query,
            @Param("userId") UUID userId,
            @Param("countryCode") String countryCode,
            @Param("dialCode") String dialCode
    );
}