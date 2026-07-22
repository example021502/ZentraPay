const express = require("express");
const router = express.Router();

/**
 * ZRemit Routes
 * Instant cross-border transfers, smart currency conversion, pay bills
 */

// Get exchange rates
router.get("/rates", (req, res) => {
  res.json({
    success: true,
    data: {
      rates: [
        { from: "GHS", to: "USD", rate: 0.0115, inverse: 87.03 },
        { from: "GHS", to: "EUR", rate: 0.0105, inverse: 95.12 },
        { from: "GHS", to: "GBP", rate: 0.0091, inverse: 110.45 },
        { from: "USD", to: "GHS", rate: 87.03, inverse: 0.0115 },
        { from: "EUR", to: "GHS", rate: 95.12, inverse: 0.0105 },
        { from: "GBP", to: "GHS", rate: 110.45, inverse: 0.0091 },
      ],
      lastUpdated: new Date().toISOString(),
    },
  });
});

// Send money abroad
router.post("/transfer", (req, res) => {
  const { amount, fromCurrency, toCurrency, recipientId, recipientBank } =
    req.body;
  res.json({
    success: true,
    message: "Transfer initiated successfully",
    data: {
      transactionId: "zremit_txn_001",
      amount,
      fromCurrency,
      toCurrency,
      recipientId,
      recipientBank,
      exchangeRate: 87.03,
      fee: "GHS 5.00",
      estimatedDelivery: "2026-07-22T12:00:00Z",
      status: "processing",
    },
  });
});

// Get transfer history
router.get("/transfers", (req, res) => {
  res.json({
    success: true,
    data: {
      transfers: [
        {
          id: "zremit_001",
          recipient: "John Doe",
          country: "Nigeria",
          amount: "GHS 500.00",
          receivedAmount: "NGN 5,750.00",
          date: "2026-07-20",
          status: "completed",
        },
        {
          id: "zremit_002",
          recipient: "Jane Smith",
          country: "Kenya",
          amount: "GHS 1,000.00",
          receivedAmount: "KES 11,500.00",
          date: "2026-07-18",
          status: "completed",
        },
      ],
    },
  });
});

// Get saved recipients
router.get("/recipients", (req, res) => {
  res.json({
    success: true,
    data: {
      recipients: [
        { id: "rec_001", name: "John Doe", country: "Nigeria", bank: "GTBank" },
        { id: "rec_002", name: "Jane Smith", country: "Kenya", bank: "KCB" },
      ],
    },
  });
});

// Pay international bills
router.post("/bills/pay", (req, res) => {
  const { billType, amount, currency, provider } = req.body;
  res.json({
    success: true,
    message: "Bill payment processed",
    data: {
      transactionId: "bill_txn_001",
      billType,
      amount,
      currency,
      provider,
      status: "completed",
    },
  });
});

module.exports = router;
