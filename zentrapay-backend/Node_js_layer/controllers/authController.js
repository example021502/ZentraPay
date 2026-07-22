const express = require("express");
const router = express.Router();
const pool = require("../config/database");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const { authenticateToken } = require("../middleware/authMiddleware");
const bcrypt = require("bcrypt");
// Import the built-in crypto module to handle the SHA-256 pre-hash execution
const crypto = require("crypto");

router.post("/", authenticateToken, async (req, res) => {
  const { pin } = req.body;
  const user_id = req.userId;

  // Defensive Check: Ensure pin is provided right at the beginning
  if (!pin) {
    return res.json({
      success: false,
      message: "Missing PIN!",
    });
  }

  // Guard Check: Make sure your pepper environment variable is loaded safely
  if (!process.env.PIN_PEPPER) {
    console.error(
      "CRITICAL ERROR: PIN_PEPPER environment variable is not defined!",
    );
    return res
      .status(500)
      .json({ success: false, error: "Internal Server Configuration Error" });
  }

  try {
    // 1. Fetch the user configuration data row from the database
    const result = await pool.query(
      "SELECT pin FROM user_authentication_pin WHERE user_id = $1",
      [user_id],
    );

    // Guard Check: Verify that the user actually has a PIN row created in the database
    if (result.rowCount === 0) {
      return res.json({
        success: false,
        message: "No PIN setup found for this user account.",
      });
    }

    // 2. Pre-hash the PIN + Pepper using HMAC SHA-256 to create a deterministic 64-character hex string.
    // This systematically protects the authentication pipeline from the 72-byte bcrypt limit limitation.
    const pepperedPinHash = crypto
      .createHmac("sha256", process.env.PIN_PEPPER)
      .update(pin)
      .digest("hex");

    // 3. Perform a secure bcrypt evaluation loop using the output hash value string representation
    const isValidPin = await bcrypt.compare(
      pepperedPinHash,
      result.rows[0].pin,
    );

    if (!isValidPin) {
      return res.json({
        success: false,
        message: "Invalid PIN!",
      });
    }

    return res.json({
      success: true,
      message: "PIN valid!",
    });
  } catch (err) {
    console.error("Error Authenticating PIN:", err);
    res.status(500).json({ status: 500, error: "Error Authenticating!" });
  }
});

module.exports = router;
