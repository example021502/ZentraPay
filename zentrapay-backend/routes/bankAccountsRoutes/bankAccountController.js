const express = require("express");
const router = express.Router();
const pool = require("../../config/db");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../.env") });
const axios = require("axios");
const { authenticateToken } = require("../../middleware/authMiddleware");

/**
 * @route GET /api/banks/paystack/banks
 * @description Fetch a list of all supported banks directly from Paystack API
 * @access Private
 */
router.get("/paystack", authenticateToken, async (req, res) => {
  const user_id = req.userId;
  const { country } = req.params;

  if (!user_id) {
    return res
      .status(400)
      .json({ success: false, error: "User ID is required." });
  }

  const checkUserQuery = "SELECT email FROM users WHERE user_id = $1"; // Fixed: Standardized to 'id' or matching column

  try {
    const userResult = await pool.query(checkUserQuery, [user_id]);

    if (userResult.rowCount === 0) {
      return res
        .status(404)
        .json({ success: false, message: "User not Found!" });
    }
    console.log("HEre....");

    // Call Paystack bank list directory API
    const paystack_response = await axios.get(
      `${process.env.PAYSTACK_BASE_API}/bank`,
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYSTACK_TEST_SK}`,
        },
      },
    );
    console.log("Banks: ", paystack_response);

    return res.status(200).json({
      success: true,
      data: paystack_response.data.data,
      message: paystack_response.data.message || "Banks fetched successfully",
    });
  } catch (err) {
    console.error(
      "Error fetching Paystack banks:",
      err.response?.data || err.message,
    );
    return res.status(err.response?.status || 500).json({
      success: false,
      message: err.response?.data?.message || "PayStack API request failed",
      error: err.response?.data || err.message,
    });
  }
});

/**
 * @route GET /api/banks/linked
 * @description Fetch local user-linked banks from the internal database
 * @access Private
 */
router.get("/linked", authenticateToken, async (req, res) => {
  const user_id = req.userId;

  if (!user_id) {
    return res
      .status(400)
      .json({ success: false, error: "User ID is required." });
  }

  const linkedBanksQuery = "SELECT * FROM banks WHERE user_id = $1";

  try {
    const user_banks = await pool.query(linkedBanksQuery, [user_id]);
    return res.status(200).json({
      success: true,
      banks: user_banks.rows,
    });
  } catch (err) {
    console.error("Error fetching linked database banks:", err);
    return res.status(500).json({
      success: false,
      error: "Database Error!",
    });
  }
});

module.exports = router;
