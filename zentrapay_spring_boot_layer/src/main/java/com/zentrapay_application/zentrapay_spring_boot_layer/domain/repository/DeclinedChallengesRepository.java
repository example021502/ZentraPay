package com.zentrapay_application.zentrapay_spring_boot_layer.domain.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.domain.model.DeclinedChallengesModel;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeclinedChallengesRepository extends JpaRepository<DeclinedChallengesModel, Integer> {
}
