const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");

// ========================================================================
// ZREMIT ROUTES - API DOCUMENTATION FOR FRONTEND
// ========================================================================
//
// Base URL: /api/zremit
//
// ENDPOINTS:
// 1. POST /api/zremit/send           - Send money (cross-border)
// 2. GET  /api/zremit/history        - Get remittance history
// 3. GET  /api/zremit/rates          - Get exchange rates
// 4. GET  /api/zremit/supported      - Get supported countries/currencies
// ========================================================================

/**
 * SEND MONEY (CROSS-BORDER)
 * =========================
 *
 * @route POST /api/zremit/send
 * @requires Authentication
 *
 * @param {string} req.body.receiverId - Recipient user ID
 * @param {number} req.body.amount - Amount to send
 * @param {string} req.body.sourceCurrency - Source currency code
 * @param {string} req.body.destinationCurrency - Destination currency code
 * @param {string} req.body.channel - MOBILE_MONEY, BANK, CASH
 * @param {string} req.body.recipientPhoneNumber - Recipient phone
 * @param {string} req.body.recipientName - Recipient full name
 *
 * @returns {Object} remittance - Remittance details
 */
router.post("/send", authenticateToken, async (req, res) => {
  const {
    receiverId,
    amount,
    sourceCurrency,
    destinationCurrency,
    channel,
    recipientPhoneNumber,
    recipientName,
  } = req.body;

  if (
    !receiverId ||
    !amount ||
    !sourceCurrency ||
    !destinationCurrency ||
    !channel ||
    !recipientPhoneNumber ||
    !recipientName
  ) {
    return res.status(400).json({
      success: false,
      message: "Missing required fields for remittance",
    });
  }

  try {
    const result = await apiClient.post("/api/zremit/send", {
      senderId: req.userId,
      receiverId,
      amount,
      sourceCurrency,
      destinationCurrency,
      channel,
      recipientPhoneNumber,
      recipientName,
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
        message: result.data?.message || "Remittance failed",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR sending remittance: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET REMITTANCE HISTORY
 * ======================
 *
 * @route GET /api/zremit/history
 * @requires Authentication
 *
 * @returns {Array} remittances - List of remittances
 */
router.get("/history", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zremit/history", {
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
        message: result.data?.message || "Failed to fetch remittance history",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching remittance history: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET EXCHANGE RATES
 * ==================
 *
 * @route GET /api/zremit/rates
 * @requires Authentication
 *
 * @returns {Object} rates - Exchange rates
 */
router.get("/rates", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zremit/rates", {
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
        message: result.data?.message || "Failed to fetch rates",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching rates: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET SUPPORTED COUNTRIES/CURRENCIES
 * ==================================
 *
 * @route GET /api/zremit/supported
 * @requires Authentication
 *
 * @returns {Object} supported - Supported countries and currencies
 */
router.get("/supported", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zremit/supported", {
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
        message: result.data?.message || "Failed to fetch supported regions",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching supported regions: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

module.exports = router;
