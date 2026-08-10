package com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.service;

import com.zentrapay_application.zentrapay_spring_boot_layer.modules.common.ResourceNotFoundException;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.model.InvestmentModel;
import com.zentrapay_application.zentrapay_spring_boot_layer.modules.zinvest.repository.InvestmentRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

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
     * Closes an investment (sells) owned by userId.
     */
    public InvestmentModel closeInvestment(UUID userId, UUID investmentId) {
        log.info("[ZINVEST] Closing investment={} for userId={}", investmentId, userId);

        InvestmentModel investment = investmentRepository.findById(investmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Investment not found"));
        if (!investment.getUserId().equals(userId)) {
            throw new ResourceNotFoundException("Investment not found");
        }

        investment.setStatus("CLOSED");
        return investmentRepository.save(investment);
    }

    // ========================================================================
    // LIQUIDITY HUB
    // Simple aggregation over existing InvestmentModel rows — not a full analytics
    // engine (no historical price snapshots are stored yet), but real computed data
    // rather than hardcoded mock values.
    // ========================================================================

    @Transactional(readOnly = true)
    public Map<String, Object> getLiquidityProfile(UUID userId) {
        List<InvestmentModel> active = investmentRepository.findByUserId(userId).stream()
                .filter(i -> "ACTIVE".equals(i.getStatus()))
                .toList();

        BigDecimal totalInvested = active.stream()
                .map(i -> i.getBuyPrice().multiply(i.getQuantity()))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalValue = active.stream()
                .map(i -> currentPriceOrBuyPrice(i).multiply(i.getQuantity()))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal totalGainLoss = totalValue.subtract(totalInvested);
        BigDecimal totalGainLossPercent = totalInvested.compareTo(BigDecimal.ZERO) == 0
                ? BigDecimal.ZERO
                : totalGainLoss.divide(totalInvested, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));

        Map<String, Object> profile = new LinkedHashMap<>();
        profile.put("totalInvested", totalInvested);
        profile.put("totalValue", totalValue);
        profile.put("totalGainLoss", totalGainLoss);
        profile.put("totalGainLossPercent", totalGainLossPercent);
        profile.put("holdingsCount", active.size());
        profile.put("riskProfile", classifyRiskProfile(active, totalValue));
        profile.put("allocationByType", allocationByType(active, totalValue));
        return profile;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getLiquidityTrend(UUID userId) {
        // No historical price snapshots are stored yet, so this is a single current-value
        // point rather than a real time series. Kept as a list so the frontend's chart
        // widget can grow into real history without an API-shape change later.
        Map<String, Object> profile = getLiquidityProfile(userId);
        Map<String, Object> point = new LinkedHashMap<>();
        point.put("label", "Now");
        point.put("value", profile.get("totalValue"));
        List<Map<String, Object>> trend = new ArrayList<>();
        trend.add(point);
        return trend;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getRisks(UUID userId) {
        List<InvestmentModel> active = investmentRepository.findByUserId(userId).stream()
                .filter(i -> "ACTIVE".equals(i.getStatus()))
                .toList();
        BigDecimal totalValue = active.stream()
                .map(i -> currentPriceOrBuyPrice(i).multiply(i.getQuantity()))
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        List<Map<String, Object>> risks = new ArrayList<>();
        if (totalValue.compareTo(BigDecimal.ZERO) > 0) {
            for (InvestmentModel investment : active) {
                BigDecimal value = currentPriceOrBuyPrice(investment).multiply(investment.getQuantity());
                BigDecimal share = value.divide(totalValue, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));
                if (share.compareTo(BigDecimal.valueOf(50)) > 0) {
                    Map<String, Object> risk = new LinkedHashMap<>();
                    risk.put("type", "CONCENTRATION");
                    risk.put("severity", "HIGH");
                    risk.put("message", investment.getSymbol() + " makes up " + share.setScale(1, RoundingMode.HALF_UP)
                            + "% of your portfolio");
                    risks.add(risk);
                }
            }
        }
        return risks;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> getAlerts(UUID userId) {
        List<InvestmentModel> active = investmentRepository.findByUserId(userId).stream()
                .filter(i -> "ACTIVE".equals(i.getStatus()))
                .toList();

        List<Map<String, Object>> alerts = new ArrayList<>();
        for (InvestmentModel investment : active) {
            BigDecimal buyPrice = investment.getBuyPrice();
            if (buyPrice.compareTo(BigDecimal.ZERO) == 0) {
                continue;
            }
            BigDecimal changePercent = currentPriceOrBuyPrice(investment).subtract(buyPrice)
                    .divide(buyPrice, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100));
            if (changePercent.compareTo(BigDecimal.valueOf(-10)) <= 0) {
                Map<String, Object> alert = new LinkedHashMap<>();
                alert.put("type", "PRICE_DROP");
                alert.put("investmentId", investment.getInvestmentId());
                alert.put("symbol", investment.getSymbol());
                alert.put("changePercent", changePercent.setScale(1, RoundingMode.HALF_UP));
                alerts.add(alert);
            }
        }
        return alerts;
    }

    private BigDecimal currentPriceOrBuyPrice(InvestmentModel investment) {
        return investment.getCurrentPrice() != null ? investment.getCurrentPrice() : investment.getBuyPrice();
    }

    private String classifyRiskProfile(List<InvestmentModel> active, BigDecimal totalValue) {
        if (totalValue.compareTo(BigDecimal.ZERO) == 0) {
            return "CONSERVATIVE";
        }
        BigDecimal cryptoShare = active.stream()
                .filter(i -> "CRYPTO".equalsIgnoreCase(i.getType()))
                .map(i -> currentPriceOrBuyPrice(i).multiply(i.getQuantity()))
                .reduce(BigDecimal.ZERO, BigDecimal::add)
                .divide(totalValue, 4, RoundingMode.HALF_UP);
        if (cryptoShare.compareTo(BigDecimal.valueOf(0.5)) >= 0) {
            return "AGGRESSIVE";
        } else if (cryptoShare.compareTo(BigDecimal.valueOf(0.2)) >= 0) {
            return "MODERATE";
        }
        return "CONSERVATIVE";
    }

    private Map<String, BigDecimal> allocationByType(List<InvestmentModel> active, BigDecimal totalValue) {
        Map<String, BigDecimal> byType = active.stream()
                .collect(Collectors.groupingBy(
                        InvestmentModel::getType,
                        LinkedHashMap::new,
                        Collectors.reducing(BigDecimal.ZERO,
                                i -> currentPriceOrBuyPrice(i).multiply(i.getQuantity()),
                                BigDecimal::add)));
        if (totalValue.compareTo(BigDecimal.ZERO) == 0) {
            return byType;
        }
        Map<String, BigDecimal> percentages = new LinkedHashMap<>();
        byType.forEach((type, value) -> percentages.put(type,
                value.divide(totalValue, 4, RoundingMode.HALF_UP).multiply(BigDecimal.valueOf(100))));
        return percentages;
    }
}