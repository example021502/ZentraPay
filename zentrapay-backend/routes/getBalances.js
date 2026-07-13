const express = require("express");
const router = express.Router();
const pool = require("../config/db");
const path = require("path");
const { authenticateToken } = require("../middleware/authMiddleware");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

router.get("/crypto/all", authenticateToken, async (req, res) => {
  const user_id = req.userId;
  if (!user_id) {
    return res.json({ success: false, message: "User Error!" });
  }
  try {
    const result = await pool.query(
      "SELECT * FROM crypto_table WHERE user_id = $1",
      [user_id],
    );
    if (result.rowCount === 0) {
      return res.json({ success: false, message: "No crypto accounts found!" });
    }
    res.json({
      success: true,
      result: result.rows,
    });
  } catch (err) {
    console.error("Crypto accounts Error:", err);
    res.status(500).json({ status: 500, message: "Database Error!" });
  }
});

router.get("/fiat/all", authenticateToken, async (req, res) => {
  const user_id = req.userId;
  if (!user_id) {
    return res.json({
      success: true,
      message: "User Error!",
    });
  }
  try {
    const result = await pool.query(
      "SELECT * FROM fiat_table WHERE user_id = $1",
      [user_id],
    );
    if (result.rowCount == 0) {
      return res.json({ success: false, message: "No fiat accounts found!" });
    }
    return res.json({
      success: true,
      result: result.rows,
    });
  } catch (err) {
    console.error("Error:", err);
    return res.status(500).json({ success: false, message: "Database Error!" });
  }
});

module.exports = router;
