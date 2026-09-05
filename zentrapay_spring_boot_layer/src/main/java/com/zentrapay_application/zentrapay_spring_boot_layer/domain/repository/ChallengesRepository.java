package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.ChallengesModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ChallengesRepository extends JpaRepository<ChallengesModel, UUID> {
}
