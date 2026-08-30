package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserProfileModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.UUID;

public interface UserProfileRepository extends JpaRepository<UserProfileModel, UUID> {
    @Query("SELECT u FROM UserProfileModel u WHERE u.userId = :userId")
    UserProfileModel getBtUserId(@Param("userId") UUID userId);
}
