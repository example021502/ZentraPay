package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.LoanModel;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface LoanRepository extends JpaRepository<LoanModel, UUID> {

    List<LoanModel> findByUserIdOrderByAppliedAtDesc(UUID userId);
}
