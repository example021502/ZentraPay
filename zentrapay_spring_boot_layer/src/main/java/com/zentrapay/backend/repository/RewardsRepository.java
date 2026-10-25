package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.RewardsModel;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface RewardsRepository extends JpaRepository<RewardsModel, Integer> {
}
