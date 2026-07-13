const express = require("express");
const router = express.Router();

// GET /api/converter/rates - Get exchange rates
router.get("/rates", (req, res) => {
  try {
    const rates = {
      GHS: { USD: 0.087, KES: 1.25, NGN: 45.5 },
      USD: { GHS: 11.49, KES: 143.5, NGN: 522.0 },
      KES: { GHS: 0.08, USD: 0.007, NGN: 3.64 },
      NGN: { GHS: 0.022, USD: 0.0019, KES: 0.275 },
    };

    res.json(rates);
  } catch (error) {
    res.status(500).json({ error: "Failed to load exchange rates" });
  }
});

// POST /api/converter/convert - Convert currency
router.post("/convert", (req, res) => {
  try {
    const { fromCurrency, toCurrency, amount, conversionType } = req.body;

    if (!fromCurrency || !toCurrency || !amount) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const exchangeRate = 0.087;
    const convertedAmount = amount * exchangeRate;
    const fee = conversionType === "smart" ? 5.0 : 2.0;

    const response = {
      fromAmount: amount,
      toAmount: convertedAmount,
      exchangeRate: exchangeRate,
      fee: fee,
      conversionType: conversionType,
    };

    res.json(response);
  } catch (error) {
    res.status(500).json({ error: "Failed to convert currency" });
  }
});

// GET /api/converter/history - Get conversion history
router.get("/history", (req, res) => {
  try {
    const history = [
      {
        id: 1,
        fromCurrency: "GHS",
        toCurrency: "USD",
        fromAmount: 1000.0,
        toAmount: 87.03,
        date: "2026-06-07",
      },
    ];

    res.json(history);
  } catch (error) {
    res.status(500).json({ error: "Failed to load conversion history" });
  }
});

module.exports = router;
