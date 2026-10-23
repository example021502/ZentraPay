package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.ChallengesModel;
import com.zentrapay.backend.service.common.Datatypes;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ChallengesRepository extends JpaRepository<ChallengesModel, UUID> {

    // Fetch active challenges available to users
    List<ChallengesModel> findByIsActiveTrue();

    // Filter active challenges by category
    List<ChallengesModel> findByIsActiveTrueAndCategory(Datatypes.ChallengeCategory category);
}