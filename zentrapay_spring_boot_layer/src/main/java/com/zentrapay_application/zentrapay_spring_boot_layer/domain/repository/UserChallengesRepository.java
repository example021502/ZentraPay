package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.UserChallengesModel;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserChallengesRepository extends JpaRepository<UserChallengesModel, Integer> {
}
