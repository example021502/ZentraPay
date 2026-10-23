package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.UserProfileModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.UUID;

public interface UserProfileRepository extends JpaRepository<UserProfileModel, UUID> {
    @Query("SELECT u FROM UserProfileModel u WHERE u.userId = :userId")
    UserProfileModel getBtUserId(@Param("userId") UUID userId);
}
