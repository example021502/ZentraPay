package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.UserProfileModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface UserProfileRepository extends JpaRepository<UserProfileModel, UUID> {
    @Query("SELECT u FROM UserProfileModel u WHERE u.userId = :userId")
    UserProfileModel getByUserId(@Param("userId") UUID userId);

    @Query("SELECT p.identityDocumentNumber FROM UserProfileModel p WHERE p.userId = :userId")
    Optional<String> getUserIdNumberByUserId(@Param("userId") UUID userId);

    /**
     * Profiles in the given review state, oldest submission first (the officer's work queue).
     */
    @Query("SELECT p FROM UserProfileModel p WHERE p.KYCStatus = :status ORDER BY p.kycSubmittedAt ASC")
    java.util.List<UserProfileModel> findByReviewStatus(@Param("status") String status,
                                                        org.springframework.data.domain.Pageable pageable);
}
