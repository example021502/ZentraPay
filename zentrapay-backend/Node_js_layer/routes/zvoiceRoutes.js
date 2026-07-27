const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");

// ========================================================================
// ZVOICE AI ROUTES - API DOCUMENTATION FOR FRONTEND
// ========================================================================
//
// Base URL: /api/zvoice
//
// ENDPOINTS:
// 1. POST /api/zvoice/command           - Record a voice command
// 2. GET  /api/zvoice/history           - Get voice command history
// 3. GET  /api/zvoice/fraud-alerts      - Get fraud alerts
// 4. GET  /api/zvoice/language/{lang}   - Get commands by language
// ========================================================================

/**
 * RECORD VOICE COMMAND
 * ====================
 *
 * @route POST /api/zvoice/command
 * @requires Authentication
 *
 * @param {string} req.body.commandType - BALANCE_CHECK, TRANSFER, PAYMENT, INQUIRY
 * @param {string} req.body.language - ENGLISH, FRENCH, SWAHILI, TWI, HAUSA
 * @param {string} req.body.transcript - Voice transcript text
 * @param {boolean} [req.body.fraudAlert] - Fraud detection flag
 * @param {string} [req.body.fraudReason] - Reason for fraud alert
 *
 * @returns {Object} command - Recorded voice command details
 */
router.post("/command", authenticateToken, async (req, res) => {
  const { commandType, language, transcript, fraudAlert, fraudReason } =
    req.body;

  if (!commandType || !language || !transcript) {
    return res.status(400).json({
      success: false,
      message: "Missing required fields: commandType, language, transcript",
    });
  }

  try {
    const result = await apiClient.post("/api/zvoice/command", {
      userId: req.userId,
      commandType,
      language,
      transcript,
      fraudAlert: fraudAlert || false,
      fraudReason: fraudReason || null,
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
        message: result.data?.message || "Failed to record voice command",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR recording voice command: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET VOICE COMMAND HISTORY
 * =========================
 *
 * @route GET /api/zvoice/history
 * @requires Authentication
 *
 * @returns {Array} commands - List of voice commands
 */
router.get("/history", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zvoice/history", {
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
        message: result.data?.message || "Failed to fetch voice history",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching voice history: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET FRAUD ALERTS
 * ================
 *
 * @route GET /api/zvoice/fraud-alerts
 * @requires Authentication
 *
 * @returns {Array} alerts - List of fraud alerts
 */
router.get("/fraud-alerts", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zvoice/fraud-alerts", {
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
        message: result.data?.message || "Failed to fetch fraud alerts",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching fraud alerts: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET COMMANDS BY LANGUAGE
 * =========================
 *
 * @route GET /api/zvoice/language/:language
 * @requires Authentication
 *
 * @param {string} req.params.language - Language code (en, fr, sw, tw, ha)
 *
 * @returns {Array} commands - List of commands in specified language
 */
router.get("/language/:language", authenticateToken, async (req, res) => {
  const { language } = req.params;

  try {
    const result = await apiClient.get(`/api/zvoice/language/${language}`, {
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
        message: result.data?.message || "Failed to fetch commands by language",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching commands by language: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

module.exports = router;
