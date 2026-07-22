const express = require("express");
const router = express.Router();

// GET /api/fraud/status - Get fraud detection status
router.get("/status", (req, res) => {
  try {
    const status = {
      enabled: true,
      lastChecked: new Date().toISOString(),
      activeMonitoring: true,
    };

    res.json(status);
  } catch (error) {
    res.status(500).json({ error: "Failed to load fraud status" });
  }
});

// GET /api/fraud/alerts - Get fraud alerts
router.get("/alerts", (req, res) => {
  try {
    const alerts = [
      {
        id: 1,
        title: "transaction blocked",
        amount: "-GHS 250 000.00",
        time: "Today, 09:20",
        icon: "warning",
        color: "#F21773",
      },
      {
        id: 2,
        title: "Received from Lucky",
        device: "iphone 15 pro",
        time: "Today, 09:20",
        icon: "phone_iphone",
        color: "#F79E1B",
      },
      {
        id: 3,
        title: "Voice verified",
        time: "Today, 09:20",
        icon: "check_circle",
        color: "#06881C",
        status: "Secure",
      },
    ];

    res.json(alerts);
  } catch (error) {
    res.status(500).json({ error: "Failed to load fraud alerts" });
  }
});

// GET /api/fraud/monitoring - Get fraud monitoring items
router.get("/monitoring", (req, res) => {
  try {
    const monitoringItems = [
      {
        id: 1,
        icon: "shield",
        title: "Unusual transactions",
        subtitle: "Monitoring large transfers",
      },
      {
        id: 2,
        icon: "person_off",
        title: "Suspicious login activity",
        subtitle: "New Device was detected",
      },
      {
        id: 3,
        icon: "mic",
        title: "Voice impersonation",
        subtitle: "Analyzing voice patterns",
      },
      {
        id: 4,
        icon: "location_on",
        title: "Unusual location",
        subtitle: "Tracking location changes",
      },
    ];

    res.json(monitoringItems);
  } catch (error) {
    res.status(500).json({ error: "Failed to load monitoring items" });
  }
});

// POST /api/fraud/report - Report fraud
router.post("/report", (req, res) => {
  try {
    const { type, description, transactionId } = req.body;

    if (!type || !description) {
      return res
        .status(400)
        .json({ error: "Type and description are required" });
    }

    const report = {
      id: Date.now(),
      type,
      description,
      transactionId,
      reportedAt: new Date().toISOString(),
      status: "under_review",
    };

    res.status(201).json(report);
  } catch (error) {
    res.status(500).json({ error: "Failed to report fraud" });
  }
});

module.exports = router;
