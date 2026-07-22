const express = require("express");
const router = express.Router();

/**
 * ZVoice AI Routes
 * Full voice control, hands-free balance checks, voice fraud alerts
 */

// Process voice command
router.post("/command", (req, res) => {
  const { command, language } = req.body;
  res.json({
    success: true,
    data: {
      command,
      language: language || "en",
      interpreted: "check_balance",
      response: "Your current balance is GHS 3,345,456.00",
      action: "display_balance",
    },
  });
});

// Get supported languages
router.get("/languages", (req, res) => {
  res.json({
    success: true,
    data: {
      languages: [
        { code: "en", name: "English", flag: "🇬🇧" },
        { code: "fr", name: "French", flag: "🇫🇷" },
        { code: "sw", name: "Swahili", flag: "🇰🇪" },
        { code: "tw", name: "Twi", flag: "🇬" },
        { code: "ha", name: "Hausa", flag: "🇳" },
      ],
    },
  });
});

// Voice balance check
router.get("/balance", (req, res) => {
  res.json({
    success: true,
    data: {
      balance: "GHS 3,345,456.00",
      voiceResponse:
        "Your current balance is three million, three hundred forty-five thousand, four hundred fifty-six Ghana Cedis.",
    },
  });
});

// Voice transfer
router.post("/transfer", (req, res) => {
  const { amount, recipient, currency } = req.body;
  res.json({
    success: true,
    message: "Voice transfer initiated",
    data: {
      transactionId: "zvoice_txn_001",
      amount,
      recipient,
      currency: currency || "GHS",
      status: "processing",
      voiceConfirmation: `Transferring ${amount} ${currency || "GHS"} to ${recipient}. Please confirm.`,
    },
  });
});

// Voice fraud alerts
router.get("/fraud-alerts", (req, res) => {
  res.json({
    success: true,
    data: {
      alerts: [
        {
          id: "alert_001",
          type: "unusual_login",
          message: "Unusual login attempt detected from new device.",
          timestamp: "2026-07-21T10:30:00Z",
          severity: "high",
        },
      ],
      voiceAlert:
        "Warning: Unusual login attempt detected from a new device. Please verify this was you.",
    },
  });
});

module.exports = router;
