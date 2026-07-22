const express = require("express");
const router = express.Router();

/**
 * Secure & Trusted Routes
 * Bank-grade security, biometric authentication, real-time fraud protection
 */

// Get security status
router.get("/status", (req, res) => {
  res.json({
    success: true,
    data: {
      overallStatus: "secure",
      lastChecked: new Date().toISOString(),
      checks: {
        biometricEnabled: true,
        twoFactorEnabled: true,
        fraudProtectionActive: true,
        lastPasswordChange: "2026-06-01",
        suspiciousActivity: false,
      },
    },
  });
});

// Enable biometric authentication
router.post("/biometric/enable", (req, res) => {
  const { type } = req.body; // fingerprint, face_id
  res.json({
    success: true,
    message: "Biometric authentication enabled",
    data: {
      type,
      enabled: true,
      timestamp: new Date().toISOString(),
    },
  });
});

// Get fraud alerts
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
          resolved: false,
        },
      ],
      totalAlerts: 1,
      unresolvedAlerts: 1,
    },
  });
});

// Get login history
router.get("/login-history", (req, res) => {
  res.json({
    success: true,
    data: {
      logins: [
        {
          id: "login_001",
          device: "iPhone 15 Pro",
          location: "Accra, Ghana",
          ip: "192.168.1.1",
          timestamp: "2026-07-21T08:00:00Z",
          status: "success",
        },
        {
          id: "login_002",
          device: "Samsung Galaxy S24",
          location: "Kumasi, Ghana",
          ip: "192.168.1.2",
          timestamp: "2026-07-20T14:30:00Z",
          status: "success",
        },
      ],
    },
  });
});

// Enable two-factor authentication
router.post("/2fa/enable", (req, res) => {
  const { method } = req.body; // sms, email, authenticator
  res.json({
    success: true,
    message: "Two-factor authentication enabled",
    data: {
      method,
      enabled: true,
      timestamp: new Date().toISOString(),
    },
  });
});

// Get security tips
router.get("/tips", (req, res) => {
  res.json({
    success: true,
    data: {
      tips: [
        {
          id: "tip_001",
          title: "Use Strong Passwords",
          description: "Mix letters, numbers & symbols",
          icon: "password",
        },
        {
          id: "tip_002",
          title: "Keep App Updated",
          description: "Latest security patches included",
          icon: "update",
        },
        {
          id: "tip_003",
          title: "Avoid Public WiFi",
          description: "Use mobile data for transactions",
          icon: "wifi_off",
        },
        {
          id: "tip_004",
          title: "Enable 2FA",
          description: "Double protection for your account",
          icon: "phonelink_lock",
        },
      ],
    },
  });
});

// Report suspicious activity
router.post("/report", (req, res) => {
  const { type, description, transactionId } = req.body;
  res.json({
    success: true,
    message: "Report submitted successfully",
    data: {
      reportId: "report_001",
      type,
      description,
      transactionId,
      status: "under_review",
      timestamp: new Date().toISOString(),
    },
  });
});

module.exports = router;
