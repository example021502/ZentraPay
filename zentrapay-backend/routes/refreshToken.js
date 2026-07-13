const express = require("express");
const router = express.Router();
const pool = require("../config/db");
const jwt = require("jsonwebtoken");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const bcrypt = require("bcrypt");

router.post("/", async (req, res) => {
  const { email, contact, password } = req.body;

  try {
    const result = await pool.query(
      "SELECT user_id, full_name, email, password FROM users WHERE email = $1 OR phone_number = $2",
      [email, contact],
    );

    if (result.rows.length == 0) {
      return res.json({ success: false, message: "No user found!" });
    }

    const passwordMatch = await bcrypt.compare(
      password,
      result.rows[0]["password"],
    );
    if (!passwordMatch) {
      return res.json({ success: false, message: "Incorrect password!" });
    }

    try {
      const wallet_information = await pool.query(
        "SELECT wallet_id FROM wallets WHERE user_id = $1",
        [result.rows[0].user_id],
      );

      const token = jwt.sign(
        {
          user_id: result.rows[0].user_id, // Usually 'id' or 'user_id' depending on your Postgres schema
          full_name: result.rows[0].full_name, // Custom username column from your database table
          email: result.rows[0].email, // Email payload attribute
        },
        process.env.JWT_SECRET_KEY, // Accessing the secret key defined in the environment variables
        {
          expiresIn: "1d",
        },
      );

      return res.json({
        success: true,
        message: "Login successful!",
        token: token,
      });
    } catch (e) {
      console.error("Error:", err);
      return res
        .status(500)
        .json({ status: 500, error: "Error Loading wallet information!" });
    }

    // Send the generated session token and user metadata safely back to the client
  } catch (err) {
    console.error("Error:", err);
    res.status(500).json({ status: 500, error: "Error Logging!" });
  }
});

module.exports = router;
