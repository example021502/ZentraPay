const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");

// ========================================================================
// ZPAY ROUTES - API DOCUMENTATION FOR FRONTEND
// ========================================================================
//
// Base URL: /api/zpay
//
// ENDPOINTS:
// 1. GET  /api/zpay/balance           - Get wallet balance
// 2. GET  /api/zpay/cards             - Get user's cards
// 3. POST /api/zpay/cards/virtual     - Create virtual card
// 4. POST /api/zpay/payment/nfc-qr    - Process NFC/QR payment
// 5. GET  /api/zpay/transactions      - Get transaction history
// 6. PATCH /api/zpay/cards/{id}/nfc   - Toggle NFC payment
// 7. PATCH /api/zpay/cards/{id}/qr    - Toggle QR payment
// ========================================================================

/**
 * GET WALLET BALANCE
 * ==================
 *
 * @route GET /api/zpay/balance
 * @requires Authentication
 *
 * @returns {Object} balance - Wallet balance details
 */
router.get("/balance", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zpay/balance", {
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
        message: result.data?.message || "Failed to fetch balance",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching balance: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET USER'S CARDS
 * ================
 *
 * @route GET /api/zpay/cards
 * @requires Authentication
 *
 * @returns {Array} cards - List of user's cards
 */
router.get("/cards", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zpay/cards", {
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
        message: result.data?.message || "Failed to fetch cards",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching cards: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * CREATE VIRTUAL CARD
 * ===================
 *
 * @route POST /api/zpay/cards/virtual
 * @requires Authentication
 *
 * @param {string} req.body.brand - Card brand (Visa, Mastercard, etc.)
 *
 * @returns {Object} card - Created card details
 */
router.post("/cards/virtual", authenticateToken, async (req, res) => {
  const { brand } = req.body;

  if (!brand) {
    return res.status(400).json({
      success: false,
      message: "Card brand is required",
    });
  }

  try {
    const result = await apiClient.post("/api/zpay/cards/virtual", {
      userId: req.userId,
      brand,
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
        message: result.data?.message || "Failed to create card",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR creating virtual card: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * PROCESS NFC/QR PAYMENT
 * ======================
 *
 * @route POST /api/zpay/payment/nfc-qr
 * @requires Authentication
 *
 * @param {string} req.body.cardId - Card ID
 * @param {number} req.body.amount - Payment amount
 * @param {string} req.body.currency - Currency code
 * @param {string} req.body.merchantId - Merchant ID
 *
 * @returns {Object} payment - Payment result
 */
router.post("/payment/nfc-qr", authenticateToken, async (req, res) => {
  const { cardId, amount, currency, merchantId } = req.body;

  if (!cardId || !amount || !currency || !merchantId) {
    return res.status(400).json({
      success: false,
      message: "Missing required fields: cardId, amount, currency, merchantId",
    });
  }

  try {
    const result = await apiClient.post("/api/zpay/payment/nfc-qr", {
      userId: req.userId,
      cardId,
      amount,
      currency,
      merchantId,
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
        message: result.data?.message || "Payment failed",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR processing NFC/QR payment: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET TRANSACTION HISTORY
 * =======================
 *
 * @route GET /api/zpay/transactions
 * @requires Authentication
 *
 * @param {number} [req.query.limit] - Number of transactions to fetch
 * @param {number} [req.query.offset] - Pagination offset
 *
 * @returns {Array} transactions - List of transactions
 */
router.get("/transactions", authenticateToken, async (req, res) => {
  const { limit = 50, offset = 0 } = req.query;

  try {
    const result = await apiClient.get("/api/zpay/transactions", {
      userId: req.userId,
      limit,
      offset,
    });

    if (result.data && result.data.success) {
      return res.json({
        success: true,
        data: result.data.result,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.data?.message || "Failed to fetch transactions",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching transactions: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * TOGGLE NFC PAYMENT
 * ==================
 *
 * @route PATCH /api/zpay/cards/:cardId/nfc
 * @requires Authentication
 *
 * @param {string} req.params.cardId - Card ID
 * @param {boolean} req.body.enabled - Enable or disable NFC
 *
 * @returns {Object} card - Updated card details
 */
router.patch("/cards/:cardId/nfc", authenticateToken, async (req, res) => {
  const { cardId } = req.params;
  const { enabled } = req.body;

  if (enabled === undefined) {
    return res.status(400).json({
      success: false,
      message: "enabled field is required",
    });
  }

  try {
    const result = await apiClient.patch(
      `/api/zpay/cards/${cardId}/nfc?enabled=${enabled}`,
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
        message: result.data?.message || "Failed to toggle NFC",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR toggling NFC: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * TOGGLE QR PAYMENT
 * ==================
 *
 * @route PATCH /api/zpay/cards/:cardId/qr
 * @requires Authentication
 *
 * @param {string} req.params.cardId - Card ID
 * @param {boolean} req.body.enabled - Enable or disable QR
 *
 * @returns {Object} card - Updated card details
 */
router.patch("/cards/:cardId/qr", authenticateToken, async (req, res) => {
  const { cardId } = req.params;
  const { enabled } = req.body;

  if (enabled === undefined) {
    return res.status(400).json({
      success: false,
      message: "enabled field is required",
    });
  }

  try {
    const result = await apiClient.patch(
      `/api/zpay/cards/${cardId}/qr?enabled=${enabled}`,
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
        message: result.data?.message || "Failed to toggle QR",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR toggling QR: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

module.exports = router;
