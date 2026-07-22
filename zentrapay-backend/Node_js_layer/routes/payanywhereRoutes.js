const express = require("express");
const router = express.Router();

/**
 * Pay Anywhere Routes
 * Scan & pay with QR, accept payments as merchant, online/offline
 */

// Generate QR code for payment
router.post("/qr/generate", (req, res) => {
  const { amount, currency, merchantId } = req.body;
  res.json({
    success: true,
    data: {
      qrCode:
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
      qrData: `zentrapay://pay?amount=${amount}&currency=${currency}&merchant=${merchantId}`,
      amount,
      currency: currency || "GHS",
      expiresAt: new Date(Date.now() + 300000).toISOString(),
    },
  });
});

// Scan and pay
router.post("/qr/pay", (req, res) => {
  const { qrData, amount, pin } = req.body;
  res.json({
    success: true,
    message: "Payment successful",
    data: {
      transactionId: "payanywhere_txn_001",
      amount,
      merchant: "Shoprite Accra Mall",
      status: "completed",
      timestamp: new Date().toISOString(),
    },
  });
});

// Merchant payment acceptance
router.post("/merchant/accept", (req, res) => {
  const { merchantId, amount, customerPhone } = req.body;
  res.json({
    success: true,
    message: "Payment received",
    data: {
      transactionId: "merchant_txn_001",
      merchantId,
      amount,
      customerPhone,
      status: "completed",
      timestamp: new Date().toISOString(),
    },
  });
});

// Get merchant dashboard stats
router.get("/merchant/stats", (req, res) => {
  res.json({
    success: true,
    data: {
      today: { transactions: 15, revenue: "GHS 450.00" },
      week: { transactions: 85, revenue: "GHS 3,200.00" },
      month: { transactions: 350, revenue: "GHS 12,500.00" },
    },
  });
});

// Offline payment
router.post("/offline/pay", (req, res) => {
  const { amount, recipientPhone, offlineCode } = req.body;
  res.json({
    success: true,
    message: "Offline payment queued",
    data: {
      transactionId: "offline_txn_001",
      amount,
      recipientPhone,
      offlineCode,
      status: "pending_sync",
      willProcessWhen: "online",
    },
  });
});

// Payment links
router.post("/link/create", (req, res) => {
  const { amount, description, currency } = req.body;
  res.json({
    success: true,
    data: {
      linkId: "link_001",
      url: "https://zentrapay.com/pay/link_001",
      amount,
      description,
      currency: currency || "GHS",
      expiresAt: new Date(Date.now() + 86400000).toISOString(),
    },
  });
});

module.exports = router;
