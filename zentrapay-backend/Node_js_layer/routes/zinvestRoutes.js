const express = require("express");
const router = express.Router();

/**
 * ZInvest Routes
 * Micro-investments (stocks, crypto, commodities) and AI-guided portfolios
 */

// Get portfolio overview
router.get("/portfolio", (req, res) => {
  res.json({
    success: true,
    data: {
      totalValue: "GHS 3,728.28",
      totalGain: "+35.6%",
      totalGainAmount: "GHS 978.28",
      holdings: [
        {
          symbol: "BTC",
          name: "Bitcoin",
          value: "GHS 1,500.00",
          gain: "+12.5%",
        },
        { symbol: "ETH", name: "Ethereum", value: "GHS 800.00", gain: "+8.3%" },
        {
          symbol: "AAPL",
          name: "Apple Inc.",
          value: "GHS 600.00",
          gain: "+5.2%",
        },
        { symbol: "GOLD", name: "Gold", value: "GHS 400.00", gain: "+3.1%" },
        {
          symbol: "GHS_BOND",
          name: "Ghana Bond",
          value: "GHS 428.28",
          gain: "+2.0%",
        },
      ],
    },
  });
});

// Get available investments
router.get("/available", (req, res) => {
  res.json({
    success: true,
    data: {
      stocks: [
        {
          symbol: "AAPL",
          name: "Apple Inc.",
          price: "GHS 150.00",
          change: "+2.5%",
        },
        {
          symbol: "GOOGL",
          name: "Alphabet Inc.",
          price: "GHS 200.00",
          change: "+1.8%",
        },
        {
          symbol: "MTN",
          name: "MTN Ghana",
          price: "GHS 5.50",
          change: "+0.5%",
        },
      ],
      crypto: [
        {
          symbol: "BTC",
          name: "Bitcoin",
          price: "GHS 300,000.00",
          change: "+3.2%",
        },
        {
          symbol: "ETH",
          name: "Ethereum",
          price: "GHS 15,000.00",
          change: "+2.1%",
        },
        { symbol: "SOL", name: "Solana", price: "GHS 500.00", change: "+5.5%" },
      ],
      commodities: [
        {
          symbol: "GOLD",
          name: "Gold",
          price: "GHS 200.00/g",
          change: "+0.8%",
        },
        {
          symbol: "SILVER",
          name: "Silver",
          price: "GHS 25.00/g",
          change: "+0.3%",
        },
      ],
    },
  });
});

// Buy investment
router.post("/buy", (req, res) => {
  const { symbol, amount, type } = req.body;
  res.json({
    success: true,
    message: "Investment purchased successfully",
    data: {
      transactionId: "zinvest_buy_001",
      symbol,
      amount,
      type,
      status: "completed",
      timestamp: new Date().toISOString(),
    },
  });
});

// Sell investment
router.post("/sell", (req, res) => {
  const { symbol, amount, type } = req.body;
  res.json({
    success: true,
    message: "Investment sold successfully",
    data: {
      transactionId: "zinvest_sell_001",
      symbol,
      amount,
      type,
      status: "completed",
      timestamp: new Date().toISOString(),
    },
  });
});

// AI portfolio recommendation
router.get("/ai-recommendation", (req, res) => {
  res.json({
    success: true,
    data: {
      recommendation:
        "Based on your risk profile, we recommend increasing your crypto allocation by 10%.",
      suggestedAllocations: [
        { type: "Stocks", percentage: 40 },
        { type: "Crypto", percentage: 30 },
        { type: "Commodities", percentage: 20 },
        { type: "Bonds", percentage: 10 },
      ],
      riskProfile: "moderate",
    },
  });
});

// Auto-invest setup
router.post("/auto-invest", (req, res) => {
  const { amount, frequency, allocations } = req.body;
  res.json({
    success: true,
    message: "Auto-invest plan created",
    data: {
      planId: "auto_invest_001",
      amount,
      frequency,
      allocations,
      status: "active",
    },
  });
});

module.exports = router;
