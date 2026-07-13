const express = require("express");
const router = express.Router();
const pool = require("../config/db");
const jwt = require("jsonwebtoken");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const crypto = require("crypto");
const bcrypt = require("bcrypt");

router.post("/", async (req, res) => {
  const { full_name, email, contact, password, country, zentag, pin } =
    req.body;

  const saltRounds = 13; // Consistent workload factor for bcrypt hashing
  const pinPepper = process.env.PIN_PEPPER;
  const passwordPepper = process.env.PASSWORD_PEPPER; // Distinct pepper specialized for pass structures

  // Initial validation check to make sure mandatory elements are parsed in body payload
  if (!full_name || !email || !contact || !password || !pin) {
    return res.json({
      success: false,
      message: "Full name, email, phone number password and pin are required!",
    });
  }

  // Guard Check: Verify that required system deployment variables are accessible
  if (!pinPepper || !passwordPepper) {
    console.error(
      "CRITICAL CONFIG ERROR: Missing PIN_PEPPER or PASSWORD_PEPPER in environment setup!",
    );
    return res.status(500).json({
      success: false,
      message: "Internal server configuration error.",
    });
  }

  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const selectUserQuery =
      "SELECT email, phone_number FROM users WHERE email = $1 OR phone_number = $2";

    const existingUser = await client.query(selectUserQuery, [email, contact]);

    // Handle collision conflicts cleanly to enforce distinct authentication metrics
    if (existingUser.rowCount !== 0) {
      if (existingUser.rows[0].email === email) {
        throw new Error("Email already in use!");
      } else if (existingUser.rows[0].phone_number === contact) {
        throw new Error("Phone number already in use!");
      }
    }

    // 1. Pre-hash password with its dedicated pepper to bypass the 72-byte bcrypt barrier
    const pepperedPasswordHash = crypto
      .createHmac("sha256", passwordPepper)
      .update(password)
      .digest("hex");

    const hashed_password = await bcrypt.hash(pepperedPasswordHash, saltRounds);

    const userInsertionQuery =
      "INSERT INTO users(full_name, phone_number, email, country, password, zentag) values($1,$2,$3,$4, $5, $6) RETURNING *";
    const values = [
      full_name,
      contact,
      email,
      country,
      hashed_password,
      zentag,
    ];
    const newUser = await client.query(userInsertionQuery, values);

    if (newUser.rowCount === 0) {
      throw new Error("Registration failed!");
    }

    // 2. Pre-hash PIN using its dedicated secret pepper to ensure optimal length parity
    const pepperedPinHash = crypto
      .createHmac("sha256", pinPepper)
      .update(pin)
      .digest("hex");

    const hashedPin = await bcrypt.hash(pepperedPinHash, saltRounds);

    const pinQuery =
      "INSERT INTO user_authentication_pin (user_id, pin) values($1,$2)";
    await client.query(pinQuery, [newUser.rows[0].user_id, hashedPin]);

    // Construct authorization token context matching your security architecture mapping specs
    const token = jwt.sign(
      {
        user_id: newUser.rows[0].user_id,
        zentag: newUser.rows[0].zentag,
        full_name: newUser.rows[0].full_name,
        email: newUser.rows[0].email,
      },
      process.env.JWT_SECRET_KEY,
      {
        expiresIn: "1d",
      },
    );

    await client.query("COMMIT");

    return res.status(200).json({
      success: true,
      message: "Registration successful!",
      token: token,
      user: {
        user_id: newUser.rows[0].user_id,
        full_name: newUser.rows[0].full_name,
        zentag: newUser.rows[0].zentag,
        email: newUser.rows[0].email,
        phone_number: newUser.rows[0].phone_number,
      },
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error("Registration aborted:", error.message);
    return res.status(500).json({
      success: false,
      message: error.message || "Internal server error.",
    });
  } finally {
    // Comment: Releases the client back to your shared pool so other API requests can use it
    client.release();
  }
});

module.exports = router;
