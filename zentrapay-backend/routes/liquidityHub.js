const express = require("express");
const router = express.Router();

// GET /api/liquidity/profile - Get liquidity profile
router.get("/profile", (req, res) => {
  try {
    const profile = {
      totalBalance: 3378345245.9,
      currency: "GHSC",
      trappedLiquidityMinimized: 90.1,
      capitalEfficiency: 88.0,
    };

    res.json(profile);
  } catch (error) {
    res.status(500).json({ error: "Failed to load liquidity profile" });
  }
});

// GET /api/liquidity/trend - Get financial exposure trend
router.get("/trend", (req, res) => {
  try {
    const trend = {
      year: 2026,
      dataPoints: [
        { month: "Jan", value: 20 },
        { month: "Feb", value: 45 },
        { month: "Mar", value: 30 },
        { month: "Apr", value: 60 },
        { month: "May", value: 50 },
        { month: "Jun", value: 75 },
      ],
    };

    res.json(trend);
  } catch (error) {
    res.status(500).json({ error: "Failed to load financial trend" });
  }
});

// GET /api/liquidity/risks - Get top risks
router.get("/risks", (req, res) => {
  try {
    const risks = [
      {
        id: 1,
        title: "Market Volatility",
        subtitle: "Risk Score",
        score: 74,
        icon: "trending_up",
      },
      {
        id: 2,
        title: "Credit Default",
        subtitle: "Risk Score",
        score: 45,
        icon: "account_balance",
      },
      {
        id: 3,
        title: "Reports",
        subtitle: "Risk Score",
        score: 23,
        icon: "warning",
      },
    ];

    res.json(risks);
  } catch (error) {
    res.status(500).json({ error: "Failed to load risks" });
  }
});

// GET /api/liquidity/alerts - Get recent alerts
router.get("/alerts", (req, res) => {
  try {
    const alerts = [
      {
        id: 1,
        title: "Critical Notification",
        time: "3 Minutes ago",
        icon: "notifications",
      },
      {
        id: 2,
        title: "Critical Notification",
        time: "3 Minutes ago",
        icon: "notifications",
      },
    ];

    res.json(alerts);
  } catch (error) {
    res.status(500).json({ error: "Failed to load alerts" });
  }
});

module.exports = router;
