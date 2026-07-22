// wallets, currency accounts, linked banks, balances
const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const https = require("https");
const axios = require("axios");

const httpsAgent = new https.Agent({ keepAlive: true });

const apiClient = axios.create({
  baseURL: process.env.SPRING_BOOT_BASE_URL,
  httpsAgent, // Reuse connections
  headers: {
    "Content-Type": "application/json",
    "X-Internal-Secret": process.env.SPRING_BOOT_SECRET_KEY,
  },
});

{
  /*
  ===============================================
  NEW WALLET ACCOUNT ROUTER
  ===============================================
  */
}

router.post("/newWallet", authenticateToken, async (req, res) => {
  const user_id = req.userId;
  const user = await apiClient.post("/api/accounts/wallets/new", data);
});

module.exports = router;
