const express = require("express");
const router = express.Router();
const pool = require("../../config/db");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../.env") });
const { authenticateToken } = require("../../middleware/authMiddleware");

router.get("/", authenticateToken, async (req, res) => {
  const { recipient_id, amount, currency_code } = req.body;
  const user_id = req.user?.user_id;

  console.log("The values are: ", user_id, recipient_id, amount, currency_code);

  if (!user_id || !recipient_id || !amount || amount <= 0 || !currency_code) {
    return res.status(400).json({
      success: false,
      message:
        "Invalid parameters. Recipient, currency code and a positive amount are required.",
    });
  }

  // Comment: This safely borrows a temporary client thread from your existing shared pool instance!
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const senderQuery =
      "SELECT balance FROM wallets WHERE user_id = $1 AND currency_code = $2 FOR UPDATE";
    const senderRes = await client.query(senderQuery, [user_id, currency_code]);

    if (senderRes.rows.length === 0) {
      throw new Error("Target currency account not found!");
    }

    const currentBalance = parseFloat(senderRes.rows[0].balance);
    if (currentBalance < amount) {
      throw new Error("Insufficient funds!");
    }

    const debitQuery =
      "UPDATE wallets SET balance = balance - $1 WHERE user_id = $2 AND currency_code = $3";
    await client.query(debitQuery, [amount, user_id, currency_code]);

    const accountExistQuery =
      "SELECT full_name FROM wallets WHERE user_id = $1 AND currency_code =$2";
    const accountExistRes = await client.query(accountExistQuery, [
      recipient_id,
      currency_code,
    ]);
    if (accountExistRes.rowCount === 0) {
      throw new Error("Recipient wallet account not found!");
    }
    const creditQuery =
      "UPDATE wallets SET balance = balance + $1 WHERE user_id = $2 AND currency_code = $3";
    const creditRes = await client.query(creditQuery, [
      amount,
      recipient_id,
      currency_code,
    ]);

    if (creditRes.rowCount === 0) {
      throw new Error("Recipient wallet target record initialization failure");
    }

    await client.query("COMMIT");

    return res.status(200).json({
      success: true,
      message: "Transaction successful!",
    });
  } catch (error) {
    await client.query("ROLLBACK");
    console.error(
      "Fintech ledger transaction aborted automatically:",
      error.message,
    );
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
