package com.zentrapay.backend.repository;

import com.zentrapay.backend.entity.LoanModel;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface LoanRepository extends JpaRepository<LoanModel, UUID> {

    List<LoanModel> findByUserIdOrderByAppliedAtDesc(UUID userId);

    // A repayment reads the loan WITH a lock so two payments at once cannot both use the same balance
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT l FROM LoanModel l WHERE l.loanId = :loanId AND l.userId = :userId")
    Optional<LoanModel> findOwnedForUpdate(@Param("loanId") UUID loanId, @Param("userId") UUID userId);
}
