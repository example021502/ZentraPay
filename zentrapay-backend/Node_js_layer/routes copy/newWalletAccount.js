const express = require("express");
const router = express.Router();
const pool = require("../config/database");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const { authenticateToken } = require("../middleware/authMiddleware");

// ============================================================
// FIAT ACCOUNT CREATION
// ============================================================
router.post("/fiat", authenticateToken, async (req, res) => {
  const { fiat_name, fiat_currency, fiat_iso_code } = req.body;
  const user_id = req.userId;

  if (!user_id) {
    return res.json({ success: false, message: "User Error!" });
  }
  console.log(fiat_name, fiat_currency, fiat_iso_code);
  if (!fiat_name || !fiat_currency || !fiat_iso_code) {
    return res.json({
      success: false,
      message: "Missing required fields",
    });
  }

  try {
    const result = await pool.query(
      "SELECT wallet_name FROM fiat_table WHERE user_id = $1 AND currency_code = $2",
      [user_id, fiat_currency],
    );

    if (result.rowCount !== 0) {
      return res.json({
        success: false,
        message:
          "An identical wallet account already exist! create an account of different Currency",
      });
    }

    const newWalletResult = await pool.query(
      "INSERT INTO fiat_table(user_id, wallet_name, currency_code, country_iso_code) VALUES($1, $2, $3, $4)",
      [user_id, fiat_name, fiat_currency, fiat_iso_code],
    );

    res.json({
      success: true,
      message: "Wallet created successfully!",
    });
  } catch (err) {
    console.error("Error:", err);
    res.status(500).json({ success: false, message: "Error creating wallet!" });
  }
});

// ============================================================
// CRYPTO ACCOUNT CREATION
// ============================================================
router.post("/crypto", authenticateToken, async (req, res) => {
  const { wallet_name, currency, country_iso_code } = req.body;
  const user_id = req.userId;

  if (!user_id) {
    return res.json({ success: false, message: "User Error!" });
  }

  if (!wallet_name || !currency || !country_iso_code) {
    return res.json({
      success: false,
      message: "Missing required fields",
    });
  }

  try {
    const result = await pool.query(
      "SELECT wallet_name FROM crypto_table WHERE user_id = $1 AND ticker_symbol = $2",
      [user_id, currency],
    );

    if (result.rowCount !== 0) {
      return res.json({
        success: false,
        message:
          "An identical account already exist! create an account of different Currency",
      });
    }

    const newCryptoAccount = await pool.query(
      "INSERT INTO crypto_table(user_id, wallet_name, ticker_symbol, icon_url) VALUES($1, $2, $3, $4)",
      [user_id, wallet_name, currency, country_iso_code],
    );

    return res.json({
      success: true,
      message: "Wallet created successfully!",
    });
  } catch (err) {
    console.error("Error:", err);
    res.status(500).json({ success: false, message: "Database Error!" });
  }
});

module.exports = router;
