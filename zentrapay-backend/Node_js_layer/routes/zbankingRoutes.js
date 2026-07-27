const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");

// ========================================================================
// ZBANKING ROUTES - API DOCUMENTATION FOR FRONTEND
// ========================================================================
//
// Base URL: /api/zbanking
//
// All endpoints require authentication via authenticateToken middleware.
// The middleware validates JWT tokens and attaches userId to req.userId.
//
// ENDPOINTS:
// 1. GET  /api/zbanking/savings           - Get user's savings accounts
// 2. POST /api/zbanking/savings/create    - Create new savings account
// 3. POST /api/zbanking/savings/{id}/deposit  - Deposit to savings
// 4. POST /api/zbanking/savings/{id}/withdraw - Withdraw from savings
// 5. GET  /api/zbanking/loans             - Get user's loans
// 6. POST /api/zbanking/loans/apply       - Apply for a loan
// 7. GET  /api/zbanking/budget            - Get budget information
// 8. GET  /api/zbanking/insights          - Get AI financial insights
// ========================================================================

/**
 * GET USER'S SAVINGS ACCOUNTS
 * ===========================
 *
 * @route GET /api/zbanking/savings
 * @requires Authentication
 *
 * @returns {Array} savings - List of savings accounts
 */
router.get("/savings", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zbanking/savings", {
      userId: req.userId,
    });

    if (result.data && result.data.success) {
      return res.json({
        success: true,
        data: result.data.result,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.data?.message || "Failed to fetch savings",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching savings: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * CREATE SAVINGS ACCOUNT
 * ======================
 *
 * @route POST /api/zbanking/savings/create
 * @requires Authentication
 *
 * @param {string} req.body.savingsName - Name for the savings account
 * @param {number} req.body.initialDeposit - Initial deposit amount
 * @param {string} req.body.currency - Currency code (e.g., "GHS", "USD")
 * @param {string} [req.body.description] - Optional description
 * @param {string} [req.body.targetDate] - Target date (ISO string)
 * @param {number} [req.body.targetAmount] - Target amount to save
 *
 * @returns {Object} savings - Created savings account details
 */
router.post("/savings/create", authenticateToken, async (req, res) => {
  const {
    savingsName,
    initialDeposit,
    currency,
    description,
    targetDate,
    targetAmount,
  } = req.body;

  if (!savingsName || !initialDeposit || !currency) {
    return res.status(400).json({
      success: false,
      message: "Missing required fields: savingsName, initialDeposit, currency",
    });
  }

  try {
    const result = await apiClient.post("/api/zbanking/savings/create", {
      userId: req.userId,
      savingsName,
      initialDeposit,
      currency,
      description,
      targetDate,
      targetAmount,
    });

    if (result.data && result.data.success) {
      return res.json({
        success: true,
        data: result.data.result,
        message: result.data.message,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.data?.message || "Failed to create savings account",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR creating savings: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * DEPOSIT TO SAVINGS
 * ==================
 *
 * @route POST /api/zbanking/savings/:savingsId/deposit
 * @requires Authentication
 *
 * @param {string} req.params.savingsId - Savings account ID
 * @param {number} req.body.amount - Amount to deposit
 *
 * @returns {Object} savings - Updated savings account
 */
router.post(
  "/savings/:savingsId/deposit",
  authenticateToken,
  async (req, res) => {
    const { savingsId } = req.params;
    const { amount } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid deposit amount",
      });
    }

    try {
      const result = await apiClient.post(
        `/api/zbanking/savings/${savingsId}/deposit?amount=${amount}`,
        {
          userId: req.userId,
        },
      );

      if (result.data && result.data.success) {
        return res.json({
          success: true,
          data: result.data.result,
          message: result.data.message,
        });
      } else {
        return res.status(400).json({
          success: false,
          message: result.data?.message || "Deposit failed",
        });
      }
    } catch (e) {
      console.error("[NODE_JS] ERROR depositing to savings: ", e);
      return res.status(500).json({ success: false, message: "Server Error!" });
    }
  },
);

/**
 * WITHDRAW FROM SAVINGS
 * ======================
 *
 * @route POST /api/zbanking/savings/:savingsId/withdraw
 * @requires Authentication
 *
 * @param {string} req.params.savingsId - Savings account ID
 * @param {number} req.body.amount - Amount to withdraw
 *
 * @returns {Object} savings - Updated savings account
 */
router.post(
  "/savings/:savingsId/withdraw",
  authenticateToken,
  async (req, res) => {
    const { savingsId } = req.params;
    const { amount } = req.body;

    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: "Invalid withdrawal amount",
      });
    }

    try {
      const result = await apiClient.post(
        `/api/zbanking/savings/${savingsId}/withdraw?amount=${amount}`,
        {
          userId: req.userId,
        },
      );

      if (result.data && result.data.success) {
        return res.json({
          success: true,
          data: result.data.result,
          message: result.data.message,
        });
      } else {
        return res.status(400).json({
          success: false,
          message: result.data?.message || "Withdrawal failed",
        });
      }
    } catch (e) {
      console.error("[NODE_JS] ERROR withdrawing from savings: ", e);
      return res.status(500).json({ success: false, message: "Server Error!" });
    }
  },
);

/**
 * GET USER'S LOANS
 * ================
 *
 * @route GET /api/zbanking/loans
 * @requires Authentication
 *
 * @returns {Array} loans - List of user's loans
 */
router.get("/loans", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zbanking/loans", {
      userId: req.userId,
    });

    if (result.data && result.data.success) {
      return res.json({
        success: true,
        data: result.data.result,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.data?.message || "Failed to fetch loans",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching loans: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * APPLY FOR LOAN
 * ==============
 *
 * @route POST /api/zbanking/loans/apply
 * @requires Authentication
 *
 * @param {string} req.body.loanType - Type of loan
 * @param {number} req.body.amount - Loan amount
 * @param {number} req.body.durationMonths - Loan duration in months
 * @param {string} [req.body.purpose] - Purpose of loan
 * @param {string} req.body.employmentStatus - Employment status
 * @param {number} [req.body.monthlyIncome] - Monthly income
 *
 * @returns {Object} loan - Loan application details
 */
router.post("/loans/apply", authenticateToken, async (req, res) => {
  const {
    loanType,
    amount,
    durationMonths,
    purpose,
    employmentStatus,
    monthlyIncome,
  } = req.body;

  if (!loanType || !amount || !durationMonths || !employmentStatus) {
    return res.status(400).json({
      success: false,
      message:
        "Missing required fields: loanType, amount, durationMonths, employmentStatus",
    });
  }

  try {
    const result = await apiClient.post("/api/zbanking/loans/apply", {
      userId: req.userId,
      loanType,
      amount,
      durationMonths,
      purpose,
      employmentStatus,
      monthlyIncome,
    });

    if (result.data && result.data.success) {
      return res.json({
        success: true,
        data: result.data.result,
        message: result.data.message,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.data?.message || "Loan application failed",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR applying for loan: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET BUDGET INFORMATION
 * ======================
 *
 * @route GET /api/zbanking/budget
 * @requires Authentication
 *
 * @returns {Object} budget - Budget information
 */
router.get("/budget", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zbanking/budget", {
      userId: req.userId,
    });

    if (result.data && result.data.success) {
      return res.json({
        success: true,
        data: result.data.result,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.data?.message || "Failed to fetch budget",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching budget: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET AI FINANCIAL INSIGHTS
 * =========================
 *
 * @route GET /api/zbanking/insights
 * @requires Authentication
 *
 * @returns {Object} insights - AI-generated financial insights
 */
router.get("/insights", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zbanking/insights", {
      userId: req.userId,
    });

    if (result.data && result.data.success) {
      return res.json({
        success: true,
        data: result.data.result,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.data?.message || "Failed to fetch insights",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching insights: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

module.exports = router;
