const express = require("express");
const router = express.Router();
const pool = require("../../config/db");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const { authenticateToken } = require("../../middleware/authMiddleware");
const bcrypt = require("bcrypt");
// Import the built-in crypto module to handle the SHA-256 pre-hash execution
const crypto = require("crypto");

router.post("/", authenticateToken, async (req, res) => {
  const user_id = req.userId;

  // Defensive Check: Ensure pin is provided right at the beginning
  if (!user_id) {
    return res.json({
      success: false,
      message: "User Error!",
    });
  }

  try {
    // 1. Fetch the user configuration data row from the database
    const result = await pool.query("SELECT * FROM bills WHERE user_id = $1", [
      user_id,
    ]);
    console.log(result);
    if (result.rowCount === 0) {
      return res.json({
        success: false,
        message: "No bill providers found.",
      });
    }

    return res.json({
      success: true,
      result: result.rows,
    });
  } catch (err) {
    console.error("Error Fetching:", err);
    res.status(500).json({ status: 500, error: "Error Fetching!" });
  }
});

module.exports = router;
