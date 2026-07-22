const express = require("express");
const { authenticateToken } = require("../middleware/authMiddleware");
const router = express.Router();

// GET /api/settings/security-score - Get security score
router.get("/security-score", authenticateToken, async (req, res) => {
  const user_id = req.userId;
  try {
    const securityScore = {
      score: 90,
      status: "Protected",
      biometricEnabled: false,
      fraudProtection: true,
    };

    res.json(securityScore);
  } catch (error) {
    res.status(500).json({ error: "Failed to load security score" });
  }
});

// POST /api/settings/biometric - Update biometric authentication
router.post("/biometric", (req, res) => {
  try {
    const { enabled } = req.body;

    const response = {
      success: true,
      biometricEnabled: enabled,
      message: enabled
        ? "Biometric authentication enabled"
        : "Biometric authentication disabled",
    };

    res.json(response);
  } catch (error) {
    res.status(500).json({ error: "Failed to update biometric auth" });
  }
});

// POST /api/settings/fraud-protection - Update fraud protection
router.post("/fraud-protection", (req, res) => {
  try {
    const { enabled } = req.body;

    const response = {
      success: true,
      fraudProtection: enabled,
      message: enabled
        ? "Fraud protection activated"
        : "Fraud protection deactivated",
    };

    res.json(response);
  } catch (error) {
    res.status(500).json({ error: "Failed to update fraud protection" });
  }
});

// GET /api/settings/protection-history - Get protection history
router.get("/protection-history", (req, res) => {
  try {
    const history = [
      {
        id: 1,
        type: "blocked",
        title: "transaction blocked",
        amount: "-GHS 250 000.00",
        time: "Today, 09:20",
        icon: "warning",
        color: "#F21773",
      },
      {
        id: 2,
        type: "device",
        title: "New Device Logged in",
        device: "iphone 15 pro",
        time: "Today, 09:20",
        icon: "phone_iphone",
        color: "#F79E1B",
      },
      {
        id: 3,
        type: "secure",
        title: "Voice verified",
        time: "Today, 09:20",
        icon: "check_circle",
        color: "#06881C",
      },
    ];

    res.json(history);
  } catch (error) {
    res.status(500).json({ error: "Failed to load protection history" });
  }
});

module.exports = router;
