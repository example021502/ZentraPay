const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");

// ========================================================================
// ZINVEST ROUTES - API DOCUMENTATION FOR FRONTEND
// ========================================================================
//
// Base URL: /api/zinvest
//
// ENDPOINTS:
// 1. GET  /api/zinvest/portfolio        - Get user's investment portfolio
// 2. POST /api/zinvest/create           - Create new investment
// 3. GET  /api/zinvest/type/{type}      - Get investments by type
// 4. GET  /api/zinvest/performance      - Get investment performance
// 5. POST /api/zinvest/{id}/sell        - Sell/close investment
// ========================================================================

/**
 * GET INVESTMENT PORTFOLIO
 * =========================
 *
 * @route GET /api/zinvest/portfolio
 * @requires Authentication
 *
 * @returns {Array} investments - List of user's investments
 */
router.get("/portfolio", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zinvest/portfolio", {
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
        message: result.data?.message || "Failed to fetch portfolio",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching portfolio: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * CREATE INVESTMENT
 * =================
 *
 * @route POST /api/zinvest/create
 * @requires Authentication
 *
 * @param {string} req.body.name - Investment name
 * @param {string} req.body.type - STOCK, CRYPTO, COMMODITY, ETF
 * @param {string} req.body.symbol - Stock symbol (AAPL, BTC, etc.)
 * @param {number} req.body.quantity - Quantity to invest
 * @param {number} req.body.buyPrice - Price per unit
 * @param {string} req.body.currency - Currency code
 *
 * @returns {Object} investment - Created investment details
 */
router.post("/create", authenticateToken, async (req, res) => {
  const { name, type, symbol, quantity, buyPrice, currency } = req.body;

  if (!name || !type || !symbol || !quantity || !buyPrice || !currency) {
    return res.status(400).json({
      success: false,
      message:
        "Missing required fields: name, type, symbol, quantity, buyPrice, currency",
    });
  }

  try {
    const result = await apiClient.post("/api/zinvest/create", {
      userId: req.userId,
      name,
      type,
      symbol,
      quantity,
      buyPrice,
      currency,
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
        message: result.data?.message || "Failed to create investment",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR creating investment: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET INVESTMENTS BY TYPE
 * =======================
 *
 * @route GET /api/zinvest/type/:type
 * @requires Authentication
 *
 * @param {string} req.params.type - Investment type (STOCK, CRYPTO, etc.)
 *
 * @returns {Array} investments - List of investments by type
 */
router.get("/type/:type", authenticateToken, async (req, res) => {
  const { type } = req.params;

  try {
    const result = await apiClient.get(`/api/zinvest/type/${type}`, {
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
        message: result.data?.message || "Failed to fetch investments by type",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching investments by type: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET INVESTMENT PERFORMANCE
 * ==========================
 *
 * @route GET /api/zinvest/performance
 * @requires Authentication
 *
 * @returns {Object} performance - Portfolio performance metrics
 */
router.get("/performance", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zinvest/performance", {
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
        message: result.data?.message || "Failed to fetch performance",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching performance: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * SELL/CLOSE INVESTMENT
 * =====================
 *
 * @route POST /api/zinvest/:investmentId/sell
 * @requires Authentication
 *
 * @param {string} req.params.investmentId - Investment ID to sell
 *
 * @returns {Object} investment - Closed investment details
 */
router.post("/:investmentId/sell", authenticateToken, async (req, res) => {
  const { investmentId } = req.params;

  try {
    const result = await apiClient.post(`/api/zinvest/${investmentId}/sell`, {
      userId: req.userId,
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
        message: result.data?.message || "Failed to sell investment",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR selling investment: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

module.exports = router;
