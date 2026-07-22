const express = require("express");
const router = express.Router();

/**
 * ZPay Wallet Routes
 * Multi-currency & crypto wallet, NFC/QR payments, virtual & physical cards,
 * contactless merchant payments
 */

// Get wallet balance summary
router.get("/balance", (req, res) => {
  res.json({
    success: true,
    data: {
      totalBalance: "GHS 3,345,456.00",
      fiatBalance: "GHS 2,500,000.00",
      cryptoBalance: "GHS 845,456.00",
      currencies: [
        { code: "GHS", balance: "1,500,000.00", symbol: "" },
        { code: "USD", balance: "50,000.00", symbol: "$" },
        { code: "EUR", balance: "25,000.00", symbol: "€" },
        { code: "BTC", balance: "0.5", symbol: "₿" },
        { code: "ETH", balance: "5.0", symbol: "Ξ" },
      ],
    },
  });
});

// Get virtual cards
router.get("/cards", (req, res) => {
  res.json({
    success: true,
    data: {
      cards: [
        {
          id: "card_001",
          type: "virtual",
          last4: "4242",
          brand: "Visa",
          status: "active",
          expiry: "12/27",
        },
        {
          id: "card_002",
          type: "physical",
          last4: "5555",
          brand: "Mastercard",
          status: "active",
          expiry: "06/28",
        },
      ],
    },
  });
});

// Create virtual card
router.post("/cards/create", (req, res) => {
  res.json({
    success: true,
    message: "Virtual card created successfully",
    data: {
      cardId: "card_new_001",
      type: "virtual",
      last4: "1234",
      brand: "Visa",
      status: "active",
    },
  });
});

// NFC/QR payment
router.post("/payment/nfc-qr", (req, res) => {
  const { amount, currency, merchantId, paymentMethod } = req.body;
  res.json({
    success: true,
    message: "Payment processed successfully",
    data: {
      transactionId: "txn_nfc_001",
      amount,
      currency,
      merchantId,
      paymentMethod,
      status: "completed",
      timestamp: new Date().toISOString(),
    },
  });
});

// Contactless merchant payment
router.post("/payment/contactless", (req, res) => {
  const { amount, currency, merchantId } = req.body;
  res.json({
    success: true,
    message: "Contactless payment processed",
    data: {
      transactionId: "txn_contactless_001",
      amount,
      currency,
      merchantId,
      status: "completed",
      timestamp: new Date().toISOString(),
    },
  });
});

// Get transaction history
router.get("/transactions", (req, res) => {
  res.json({
    success: true,
    data: {
      transactions: [
        {
          id: "txn_001",
          type: "payment",
          amount: "GHS 150.00",
          merchant: "Shoprite Accra",
          date: "2026-07-21",
          status: "completed",
        },
        {
          id: "txn_002",
          type: "transfer",
          amount: "GHS 500.00",
          recipient: "John Doe",
          date: "2026-07-20",
          status: "completed",
        },
      ],
    },
  });
});

module.exports = router;
