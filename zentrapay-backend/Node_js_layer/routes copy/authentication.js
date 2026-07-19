const express = require("express");
const router = express.Router();
const pool = require("../config/database");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const bcrypt = require("bcrypt");
// Import the built-in crypto module to handle the SHA-256 pre-hash execution
const crypto = require("crypto");

{
  /*
  ===============================================
  LOGIN ROUTER
  ===============================================
  */
}
router.post("/login", async (req, res) => {
  const { email, phone_number, password } = req.body;

  // Defensive Check: Ensure pin is provided right at the beginning
  if (!email || !password || !phone_number) {
    return res.json({
      success: false,
      message: "Missing Email/Phone number and Password!",
    });
  }

  // Guard Check: Make sure your pepper environment variable is loaded safely
  if (!process.env.PASSWORD_PEPPER) {
    console.error("CRITICAL ERROR:: PASSWORD_PEPPER ERROR!");
    return res.json({ success: false, message: "Configuration Error!" });
  }

  try {
    // 1. Fetch the user configuration data row from the database
    const result = await pool.query(
      "SELECT user_id, full_name, password FROM users WHERE email = $1 OR phone_number",
      [email, phone_number],
    );

    // Guard Check: Verify that the user actually has a PIN row created in the database
    if (result.rowCount === 0) {
      return res.json({
        success: false,
        message: "User not Found!",
      });
    }
    const passwordPepper = process.env.PASSWORD_PEPPER;
    const pepperedPasswordHash = crypto
      .createHmac("sha256", passwordPepper)
      .update(password)
      .digest("hex");
    // 3. Perform a secure bcrypt evaluation loop using the output hash value string representation
    const isValidPassword = await bcrypt.compare(
      pepperedPasswordHash,
      result.rows[0].password,
    );

    if (!isValidPassword) {
      return res.json({
        success: false,
        message: "Invalid Password!",
      });
    }

    const token = jwt.sign(
      {
        user_id: result.rows[0].user_id,
        full_name: result[0].full_name,
        email: result.rows[0].email,
      },
      process.env.JWT_SECRET_KEY,
      {
        expiresIn: "24h",
      },
    );

    return res.json({
      success: true,
      message: "Login Successful!",
      token: token,
      user: {
        full_name: rows[0].full_name,
        email: rows[0].email,
      },
    });
  } catch (err) {
    console.error("ERROR::", err);
    res.json({ status: false, message: "Login Failed!" });
  }
});

{
  /*
  ===============================================
  REGISTER ROUTER
  ===============================================
  */
}
router.post("/register", async (req, res) => {
  const { full_name, email, phone_number, password, pin, country } = req.body;

  // Defensive Check: Ensure pin is provided right at the beginning
  if (!full_name || !email || !password || !phone_number || !pin) {
    return res.json({
      success: false,
      message: "Missing value(s)!",
    });
  }

  try {
    // 1. Fetch the user configuration data row from the database
    const result = await pool.query(
      "SELECT email, phone_number FROM users WHERE email = $1 OR phone_number = $2",
      [email, phone_number],
    );

    // Guard Check: Verify that the user actually has a PIN row created in the database
    if (result.rowCount !== 0) {
      if (result[0].email === email) {
        return res.json({
          success: false,
          message: "Email already in use.",
        });
      }
      return res.json({
        success: false,
        message: "Phone number already in use.",
      });
    }
    const saltRounds = 13;
    const passwordPepper = process.env.PASSWORD_PEPPER;
    const PinPepper = process.env.PIN_PEPPER;
    const pepperedPasswordHash = crypto
      .createHmac("sha256", passwordPepper)
      .update(password)
      .digest("hex");
    const hashed_password = await bcrypt.hash(pepperedPasswordHash, saltRounds);

    const pepperedPinHash = crypto
      .createHmac("sha256", pinPepper)
      .update(pin)
      .digest("hex");

    const hashedPin = await bcrypt.hash(pepperedPinHash, saltRounds);

    const zentag = `${email.split("@")[0].trim()}@zentrapay`;
    const userInsertionQuery =
      "INSERT INTO users(full_name, phone_number, email, country, password, zentag, pin) values($1,$2,$3,$4, $5, $6, $7) RETURNING (user_id, email, full_name)";

    const values = [
      full_name,
      phone_number,
      email,
      country,
      hashed_password,
      zentag,
      hashedPin,
    ];
    const newUser = await client.query(userInsertionQuery, values);

    const token = jwt.sign(
      {
        user_id: newUser.rows[0].user_id,
        full_name: newUser[0].full_name,
        email: newUser.rows[0].email,
      },
      process.env.JWT_SECRET_KEY,
      {
        expiresIn: "24h",
      },
    );

    return res.json({
      success: true,
      message: "Registration Successful!",
      token: token,
      user: {
        full_name: newUser[0].full_name,
        email: newUser[0].email,
      },
    });
  } catch (err) {
    console.error("ERROR::", err);
    res.json({ success: false, message: "Registering Error! try again" });
  }
});

module.exports = router;
