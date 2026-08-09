package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model.Loan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface LoanRepository extends JpaRepository<Loan, UUID> {
    List<Loan> findByUserId(UUID userId);
}
