package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.repository;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model.LoanRepayment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface LoanRepaymentRepository extends JpaRepository<LoanRepayment, UUID> {
    List<LoanRepayment> findByLoanId(UUID loanId);
}
