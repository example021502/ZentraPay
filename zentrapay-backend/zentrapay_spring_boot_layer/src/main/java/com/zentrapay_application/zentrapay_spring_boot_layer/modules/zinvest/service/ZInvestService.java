package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.model.InvestmentModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.repository.InvestmentRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Service for ZInvest: micro-investments in stocks, crypto, commodities with AI-guided portfolios.
 */
@Service
@Transactional
public class ZInvestService {

    private static final Logger log = LoggerFactory.getLogger(ZInvestService.class);

    private final InvestmentRepository investmentRepository;

    public ZInvestService(InvestmentRepository investmentRepository) {
        this.investmentRepository = investmentRepository;
    }

    /**
     * Creates a new investment for a user.
     */
    public InvestmentModel createInvestment(UUID userId, String name, String type, String symbol,
                                           BigDecimal quantity, BigDecimal buyPrice, String currency) {
        log.info("[ZINVEST] Creating investment: userId={}, name={}, type={}", userId, name, type);

        InvestmentModel investment = new InvestmentModel();
        investment.setUserId(userId);
        investment.setName(name);
        investment.setType(type);
        investment.setSymbol(symbol);
        investment.setQuantity(quantity);
        investment.setBuyPrice(buyPrice);
        investment.setCurrentPrice(buyPrice); // Initially same as buy price
        investment.setCurrency(currency);
        investment.setStatus("ACTIVE");

        return investmentRepository.save(investment);
    }

    /**
     * Retrieves all investments for a user.
     */
    @Transactional(readOnly = true)
    public List<InvestmentModel> getUserInvestments(UUID userId) {
        log.info("[ZINVEST] Fetching investments for userId={}", userId);
        return investmentRepository.findByUserId(userId);
    }

    /**
     * Retrieves investments by type.
     */
    @Transactional(readOnly = true)
    public List<InvestmentModel> getInvestmentsByType(UUID userId, String type) {
        log.info("[ZINVEST] Fetching {} investments for userId={}", type, userId);
        return investmentRepository.findByUserIdAndType(userId, type);
    }

    /**
     * Updates the current price of an investment.
     */
    public InvestmentModel updateCurrentPrice(UUID investmentId, BigDecimal newPrice) {
        log.info("[ZINVEST] Updating price for investment={}, newPrice={}", investmentId, newPrice);

        InvestmentModel investment = investmentRepository.findById(investmentId)
                .orElseThrow(() -> new RuntimeException("Investment not found"));

        investment.setCurrentPrice(newPrice);
        return investmentRepository.save(investment);
    }

    /**
     * Closes an investment (sells).
     */
    public InvestmentModel closeInvestment(UUID investmentId) {
        log.info("[ZINVEST] Closing investment={}", investmentId);

        InvestmentModel investment = investmentRepository.findById(investmentId)
                .orElseThrow(() -> new RuntimeException("Investment not found"));

        investment.setStatus("CLOSED");
        return investmentRepository.save(investment);
    }
}