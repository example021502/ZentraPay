const express = require("express");
const router = express.Router();
const pool = require("../config/database");
const jwt = require("jsonwebtoken");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const bcrypt = require("bcrypt");
// Import the built-in crypto module to replicate the registration pipeline hashing
const crypto = require("crypto");

router.post("/", async (req, res) => {
  const { email, contact, password } = req.body;
  const passwordPepper = process.env.PASSWORD_PEPPER;

  // Defensive Check: Ensure password and at least one identifier are present
  if (!password || (!email && !contact)) {
    return res.json({
      success: false,
      message: "Password and Email/Phone number are required!",
    });
  }

  // Guard Check: Make sure the required password pepper is loaded safely from system environment variables
  if (!passwordPepper) {
    console.error(
      "CRITICAL CONFIG ERROR: PASSWORD_PEPPER environment variable is not defined!",
    );
    return res.status(500).json({
      success: false,
      message: "Internal server configuration error.",
    });
  }

  try {
    // Select the necessary columns, including phone_number to return valid payload metadata later
    const result = await pool.query(
      "SELECT user_id, full_name, email, password, zentag, phone_number FROM users WHERE email = $1 OR phone_number = $2",
      [email, contact],
    );

    if (result.rowCount === 0) {
      return res.json({ success: false, message: "No user found!" });
    }

    // 1. Re-create the exact SHA-256 hash of the plain-text input password combined with the pepper
    const pepperedPasswordHash = crypto
      .createHmac("sha256", passwordPepper)
      .update(password)
      .digest("hex");

    // 2. Safely evaluate the pre-hashed string value against the database record using bcrypt
    const passwordMatch = await bcrypt.compare(
      pepperedPasswordHash,
      result.rows[0]["password"],
    );

    if (!passwordMatch) {
      return res.json({ success: false, message: "Incorrect password!" });
    }

    const isNamePesent =
      result.rows[0].full_name !== null || result.rows[0].full_name !== "";

    // 3. Construct and sign the session identity token
    const token = jwt.sign(
      {
        user_id: result.rows[0].user_id,
        phone_number: result.rows[0].phone_number,
        full_name: isNamePesent
          ? result.rows[0].full_name
          : result.rows[0].email.split("@")[0],
        email: result.rows[0].email,
      },

      process.env.JWT_SECRET_KEY,
      {
        expiresIn: "1d",
      },
    );

    // 4. Send the generated session token and user metadata safely back to the client
    return res.json({
      success: true,
      message: "Login successful!",
      token: token,
      user: {
        user_id: result.rows[0].user_id,
        full_name: result.rows[0].full_name,
        zentag: result.rows[0].zentag,
        email: result.rows[0].email,
        phone_number: result.rows[0].phone_number, // Fixed property mapping reference
      },
    });
  } catch (err) {
    console.error("Error Logging in:", err);
    res.status(500).json({ status: 500, error: "Error Logging!" });
  }
});

module.exports = router;
