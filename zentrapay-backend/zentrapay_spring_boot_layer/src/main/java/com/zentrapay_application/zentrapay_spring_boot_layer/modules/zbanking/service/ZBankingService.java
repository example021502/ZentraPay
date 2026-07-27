package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.dto.SavingsRequestDTO;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.model.SavingsModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zbanking.repository.SavingsRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Service for ZBanking features: digital savings, micro-loans, budgeting, and AI insights.
 */
@Service
@Transactional
public class ZBankingService {

    private static final Logger log = LoggerFactory.getLogger(ZBankingService.class);

    private final SavingsRepository savingsRepository;

    public ZBankingService(SavingsRepository savingsRepository) {
        this.savingsRepository = savingsRepository;
    }

    /**
     * Creates a new savings account for a user.
     */
    public SavingsModel createSavingsAccount(UUID userId, SavingsRequestDTO request) {
        log.info("[ZBANKING] Creating savings account for userId={}, name={}", userId, request.savingsName());

        SavingsModel savings = new SavingsModel();
        savings.setUserId(userId);
        savings.setSavingsName(request.savingsName());
        savings.setBalance(request.initialDeposit());
        savings.setCurrency(request.currency());
        savings.setDescription(request.description());
        savings.setTargetDate(request.targetDate());
        savings.setTargetAmount(request.targetAmount());
        savings.setStatus("ACTIVE");

        return savingsRepository.save(savings);
    }

    /**
     * Retrieves all savings accounts for a user.
     */
    @Transactional(readOnly = true)
    public List<SavingsModel> getUserSavings(UUID userId) {
        log.info("[ZBANKING] Fetching savings accounts for userId={}", userId);
        return savingsRepository.findByUserId(userId);
    }

    /**
     * Deposits funds into a savings account.
     */
    public SavingsModel depositToSavings(UUID savingsId, BigDecimal amount) {
        log.info("[ZBANKING] Depositing {} into savings account {}", amount, savingsId);

        SavingsModel savings = savingsRepository.findById(savingsId)
                .orElseThrow(() -> new RuntimeException("Savings account not found"));

        savings.setBalance(savings.getBalance().add(amount));
        return savingsRepository.save(savings);
    }

    /**
     * Withdraws funds from a savings account.
     */
    public SavingsModel withdrawFromSavings(UUID savingsId, BigDecimal amount) {
        log.info("[ZBANKING] Withdrawing {} from savings account {}", amount, savingsId);

        SavingsModel savings = savingsRepository.findById(savingsId)
                .orElseThrow(() -> new RuntimeException("Savings account not found"));

        if (savings.getBalance().compareTo(amount) < 0) {
            throw new RuntimeException("Insufficient balance in savings account");
        }

        savings.setBalance(savings.getBalance().subtract(amount));
        return savingsRepository.save(savings);
    }
}