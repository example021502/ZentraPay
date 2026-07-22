const express = require("express");
const router = express.Router();

/**
 * ZBank Lite Routes
 * Digital savings & micro-loans, AI-powered financial insights,
 * auto-budgeting & tracking, emergency vault
 */

// Get savings accounts
router.get("/savings", (req, res) => {
  res.json({
    success: true,
    data: {
      accounts: [
        {
          id: "sav_001",
          name: "Emergency Fund",
          balance: "GHS 5,000.00",
          interestRate: "12.5%",
          goal: "GHS 10,000.00",
        },
        {
          id: "sav_002",
          name: "Vacation Fund",
          balance: "GHS 2,500.00",
          interestRate: "10.0%",
          goal: "GHS 5,000.00",
        },
      ],
    },
  });
});

// Create savings account
router.post("/savings/create", (req, res) => {
  const { name, initialDeposit, goal } = req.body;
  res.json({
    success: true,
    message: "Savings account created successfully",
    data: {
      id: "sav_new_001",
      name,
      balance: initialDeposit || "GHS 0.00",
      goal: goal || "GHS 0.00",
      interestRate: "12.5%",
    },
  });
});

// Get micro-loans
router.get("/loans", (req, res) => {
  res.json({
    success: true,
    data: {
      availableLoans: [
        {
          id: "loan_001",
          type: "personal",
          maxAmount: "GHS 5,000.00",
          interestRate: "15%",
          term: "6 months",
        },
        {
          id: "loan_002",
          type: "business",
          maxAmount: "GHS 20,000.00",
          interestRate: "12%",
          term: "12 months",
        },
      ],
      activeLoans: [],
    },
  });
});

// Apply for micro-loan
router.post("/loans/apply", (req, res) => {
  const { amount, type, term } = req.body;
  res.json({
    success: true,
    message: "Loan application submitted",
    data: {
      applicationId: "loan_app_001",
      amount,
      type,
      term,
      status: "pending",
    },
  });
});

// Get budget overview
router.get("/budget", (req, res) => {
  res.json({
    success: true,
    data: {
      monthlyBudget: "GHS 3,000.00",
      spent: "GHS 1,800.00",
      remaining: "GHS 1,200.00",
      categories: [
        { name: "Food", budget: "GHS 800.00", spent: "GHS 600.00" },
        { name: "Transport", budget: "GHS 400.00", spent: "GHS 300.00" },
        { name: "Utilities", budget: "GHS 500.00", spent: "GHS 450.00" },
        { name: "Entertainment", budget: "GHS 300.00", spent: "GHS 200.00" },
      ],
    },
  });
});

// Get emergency vault
router.get("/vault", (req, res) => {
  res.json({
    success: true,
    data: {
      vaultBalance: "GHS 10,000.00",
      lockedUntil: "2027-01-01",
      interestEarned: "GHS 500.00",
    },
  });
});

// AI financial insights
router.get("/insights", (req, res) => {
  res.json({
    success: true,
    data: {
      insights: [
        {
          id: "insight_001",
          type: "savings",
          message: "You are on track to save GHS 40 this week.",
          priority: "medium",
        },
        {
          id: "insight_002",
          type: "spending",
          message: "Your food spending is 25% higher than last month.",
          priority: "high",
        },
      ],
    },
  });
});

module.exports = router;
