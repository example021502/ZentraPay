const express = require("express");
const router = express.Router();
const pool = require("../../config/db");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../.env") });
const { authenticateToken } = require("../../middleware/authMiddleware");
const paystackService = require("../../services/paystackService");
const axios = require("axios");
const { v4: uuidv4 } = require("uuid");

// ============================================
// INITIALIZE EXTERNAL PAYMENT
// ============================================
router.post("/", authenticateToken, async (req, res) => {
  const user_id = req.userId;
  const {
    amount,
    currency_code,
    bank_name,
    bank_code,
    type,
    account_number,
    account_name,
    description,
    receiver_country,
  } = req.body;

  console.log(
    "Fields received: ",
    amount,
    currency_code,
    bank_name,
    bank_code,
    type,
    account_number,
    account_name,
    receiver_country,
  );

  if (!user_id) {
    return res.status(401).json({ success: false, message: "User Error!" });
  }

  console.log("Reached checkpoint: ", type, currency_code);

  // Validate incoming payment fields
  if (
    amount <= 0 ||
    !currency_code ||
    !bank_name ||
    !bank_code ||
    !account_name ||
    !account_number
  ) {
    return res.status(400).json({
      success: false,
      message: "Error: Verify the payment details you provided!",
    });
  }

  const balanceQuery =
    "SELECT balance FROM wallets WHERE user_id = $1 AND currency_code = $2";
  const userQuery = "SELECT email, country FROM users WHERE user_id = $1";

  try {
    // Run database validation checks in parallel
    const [balanceResult, userResult] = await Promise.all([
      pool.query(balanceQuery, [user_id, currency_code]),
      pool.query(userQuery, [user_id]),
    ]);

    if (userResult.rowCount === 0) {
      return res
        .status(404)
        .json({ success: false, message: "User Account Error!" });
    }

    if (balanceResult.rowCount === 0) {
      return res.status(400).json({
        success: false,
        message: `You don't have a wallet holding ${currency_code}`,
      });
    }

    const currentBalance = parseFloat(balanceResult.rows[0].balance);
    if (currentBalance < parseFloat(amount)) {
      return res
        .status(400)
        .json({ success: false, message: "Insufficient funds" });
    }

    const userEmail = userResult.rows[0].email;
    const userCountry = userResult.rows[0].country;

    // Step 1: Create Transfer Recipient via Paystack
    const recipientResponse = await axios.post(
      "https://api.paystack.co/transferrecipient",
      {
        currency_code: "NGN",
        bank_name: "Wema Bank",
        bank_code: "057",
        type: "nuban",
        account_number: "0000000000",
        account_name: "Testing Nigeria",
        receiver_country: "NG",
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYSTACK_TEST_SK}`,
          "Content-Type": "application/json",
        },
      },
    );

    console.log("Recipient validation status: ", recipientResponse.data);
    if (!recipientResponse.data || !recipientResponse.data.status) {
      return res.status(422).json({
        success: false,
        message: "Payment Failed! PayStack Verification Error!",
      });
    }

    const recipientCode = recipientResponse.data.data.recipient_code;
    const txRef = `TXN-${Date.now()}-${uuidv4().split("-")[0]}`;

    // Step 2: Initiate Transfer via Paystack Balance
    const transferResponse = await axios.post(
      "https://api.paystack.co/transfer",
      {
        source: "balance",
        // amount: Math.round(amount * 100),
        amount: 50 * 100,
        email: userEmail,
        recipient: recipientCode,
        reference: txRef,
        reason: description || "Bank Transfer",
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYSTACK_TEST_SK}`,
          "Content-Type": "application/json",
        },
      },
    );

    // Save initial transaction entry to the database
    const transactionResult = await pool.query(
      `INSERT INTO transactions (sender_id, receiver_id, send_amount, receive_amount, source_currency, destination_currency, sender_country, receiver_country, status, gateway_reference, payment_reference) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11) RETURNING transaction_id`,
      [
        user_id,
        recipientCode,
        amount,
        amount,
        currency_code,
        currency_code,
        userCountry,
        receiver_country,
        transferResponse.data.status || "pending",
        transferResponse.data.data?.transfer_code || "N/A",
        txRef,
      ],
    );

    const transactionId = transactionResult.rows[0].transaction_id;

    if (!transferResponse.data.status) {
      await pool.query(
        "UPDATE transactions SET status = $1 WHERE transaction_id = $2",
        ["failed", transactionId],
      );

      return res.status(400).json({
        success: false,
        message: transferResponse.data.message || "Transaction Failed!",
      });
    }

    return res.status(200).json({
      success: true,
      message: "Transaction Initialized Successfully",
      result: {
        transaction_id: transactionId,
        reference: txRef,
        status: transferResponse.data.data.status || "pending",
      },
    });
  } catch (error) {
    // Intercept detailed Paystack API failures (like invalid bank codes or account numbers)
    if (error.response) {
      console.error("Paystack Gateway Rejection Data:", error.response.data);
      return res.status(error.response.status).json({
        success: false,
        message: `Gateway Error: ${error.response.data.message || "Validation failed"}`,
        error_details: error.response.data,
      });
    }

    console.error("Initiate External Payment Unexpected System Error:", error);
    return res.status(500).json({
      success: false,
      message:
        "Error: Transaction processing failed due to an internal system error!",
    });
  }
});

// ============================================
// VERIFY EXTERNAL PAYMENT
// ============================================
router.get("/external/verify", async (req, res) => {
  try {
    const { reference } = req.query;

    if (!reference) {
      return res.status(400).json({
        success: false,
        message: "Transaction reference is required",
      });
    }

    const verificationResponse = await paystackService.verifyPayment(reference);

    if (!verificationResponse.success) {
      return res.status(400).json({
        success: false,
        message: verificationResponse.message,
      });
    }

    const transactionResult = await pool.query(
      "SELECT * FROM transactions WHERE payment_reference = $1",
      [reference],
    );

    if (transactionResult.rows.length === 0) {
      return res
        .status(404)
        .json({ success: false, message: "Transaction not found" });
    }

    const transaction = transactionResult.rows[0];

    if (transaction.status === "completed") {
      return res.status(200).json({
        success: true,
        status: verificationResponse.status,
        message: "Payment already completed",
        data: {
          transaction_id: transaction.transaction_id,
          reference,
          amount: transaction.send_amount,
          currency: transaction.source_currency,
          status: "success",
        },
      });
    }

    if (verificationResponse.status !== "success") {
      await pool.query(
        "UPDATE transactions SET status = $1, metadata = metadata || $2 WHERE transaction_id = $3",
        [
          "failed",
          JSON.stringify({ paystack_data: verificationResponse }),
          transaction.transaction_id,
        ],
      );

      return res.status(200).json({
        success: true,
        status: verificationResponse.status,
        message: "Payment failed",
        data: {
          transaction_id: transaction.transaction_id,
          reference,
          amount: transaction.send_amount,
          currency: transaction.source_currency,
          status: verificationResponse.status,
        },
      });
    }

    const amount = transaction.send_amount;
    const sender_id = transaction.sender_id;
    const currency_code = transaction.source_currency;

    const updateWallet = `
      UPDATE wallets
      SET balance = balance - $1
      WHERE user_id = $2 AND currency_code = $3 AND balance >= $1
    `;

    const walletResult = await pool.query(updateWallet, [
      amount,
      sender_id,
      currency_code,
    ]);

    if (walletResult.rowCount === 0) {
      await pool.query(
        "UPDATE transactions SET status = $1, metadata = metadata || $2 WHERE transaction_id = $3",
        [
          "failed",
          JSON.stringify({
            error:
              "Wallet update failed due to insufficient funds at execution",
          }),
          transaction.transaction_id,
        ],
      );

      return res.status(400).json({
        success: false,
        message: "Failed to update wallet balance",
      });
    }

    await pool.query(
      `UPDATE transactions
       SET status = $1, paid_at = CURRENT_TIMESTAMP, metadata = metadata || $2
       WHERE transaction_id = $3`,
      [
        "completed",
        JSON.stringify({ paystack_data: verificationResponse }),
        transaction.transaction_id,
      ],
    );

    return res.status(200).json({
      success: true,
      status: "success",
      message: "Payment successful and ledger updated",
      data: {
        transaction_id: transaction.transaction_id,
        reference,
        amount: transaction.send_amount,
        currency: transaction.source_currency,
        status: "success",
      },
    });
  } catch (error) {
    console.error("Payment Verification Error:", error);
    return res
      .status(500)
      .json({ success: false, message: "Failed to verify payment" });
  }
});

// ============================================
// WEBHOOK HANDLER
// ============================================
router.post("/external/webhook", async (req, res) => {
  try {
    const signature = req.headers["x-paystack-signature"];
    const payload = JSON.stringify(req.body);

    if (!signature) {
      return res.status(401).json({ error: "Missing signature" });
    }

    const isValidSignature = paystackService.verifyWebhookSignature(
      signature,
      payload,
    );

    if (!isValidSignature) {
      return res.status(401).json({ error: "Invalid signature" });
    }

    const event = req.body;

    switch (event.event) {
      case "charge.success":
        await handleSuccessfulPayment(event.data);
        break;
      case "charge.failed":
        await handleFailedPayment(event.data);
        break;
      case "transfer.success":
        await handleSuccessfulTransfer(event.data);
        break;
      case "transfer.failed":
        await handleFailedTransfer(event.data);
        break;
      default:
        console.log(`Unhandled webhook event: ${event.event}`);
    }

    return res.status(200).json({ received: true });
  } catch (error) {
    console.error("Webhook Processing Error:", error);
    return res.status(500).json({ error: "Webhook processing failed" });
  }
});

// ============================================
// WEBHOOK EVENT HANDLERS
// ============================================
async function handleSuccessfulPayment(data) {
  try {
    const reference = data.reference;
    const amount = data.amount / 100;

    const transactionResult = await pool.query(
      "SELECT * FROM transactions WHERE payment_reference = $1",
      [reference],
    );

    if (transactionResult.rows.length === 0) return;

    const transaction = transactionResult.rows[0];
    if (transaction.status === "completed") return;

    const updateWallet = `
      UPDATE wallets
      SET balance = balance - $1
      WHERE user_id = $2 AND currency_code = $3 AND balance >= $1
    `;

    const walletResult = await pool.query(updateWallet, [
      amount,
      transaction.sender_id,
      transaction.source_currency,
    ]);

    if (walletResult.rowCount === 0) {
      await pool.query(
        "UPDATE transactions SET status = $1, metadata = metadata || $2 WHERE payment_reference = $3",
        [
          "failed",
          JSON.stringify({ error: "Wallet update failed on webhook" }),
          reference,
        ],
      );
      return;
    }

    await pool.query(
      `UPDATE transactions
       SET status = $1, paid_at = CURRENT_TIMESTAMP, metadata = metadata || $2
       WHERE transaction_id = $3`,
      [
        "completed",
        JSON.stringify({ paystack_data: data }),
        transaction.transaction_id,
      ],
    );
  } catch (error) {
    console.error("Error handling successful payment:", error);
  }
}

async function handleFailedPayment(data) {
  try {
    const reference = data.reference;
    await pool.query(
      "UPDATE transactions SET status = $1, metadata = metadata || $2 WHERE payment_reference = $3",
      ["failed", JSON.stringify({ paystack_data: data }), reference],
    );
  } catch (error) {
    console.error("Error handling failed payment:", error);
  }
}

async function handleSuccessfulTransfer(data) {
  try {
    const reference = data.reference;
    const transactionResult = await pool.query(
      "SELECT * FROM transactions WHERE payment_reference = $1",
      [reference],
    );

    if (transactionResult.rows.length === 0) return;

    const transaction = transactionResult.rows[0];
    if (transaction.status === "completed") return;

    await pool.query(
      "UPDATE transactions SET status = $1, metadata = metadata || $2 WHERE payment_reference = $3",
      ["completed", JSON.stringify({ transfer_data: data }), reference],
    );
  } catch (error) {
    console.error("Error handling successful transfer:", error);
  }
}

async function handleFailedTransfer(data) {
  try {
    const reference = data.reference;
    await pool.query(
      "UPDATE transactions SET status = $1, metadata = metadata || $2 WHERE payment_reference = $3",
      ["failed", JSON.stringify({ transfer_data: data }), reference],
    );
  } catch (error) {
    console.error("Error handling failed transfer:", error);
  }
}

// ============================================
// GET TRANSACTION STATUS
// ============================================
router.get(
  "/external/status/:reference",
  authenticateToken,
  async (req, res) => {
    try {
      const { reference } = req.params;
      const user_id = req.userId;

      if (!reference) {
        return res.status(400).json({
          success: false,
          message: "Transaction reference is required",
        });
      }

      const verificationResponse =
        await paystackService.verifyPayment(reference);

      if (!verificationResponse.success) {
        return res
          .status(400)
          .json({ success: false, message: verificationResponse.message });
      }

      const transactionQuery =
        "SELECT * FROM transactions WHERE payment_reference = $1 AND sender_id = $2";
      const transactionResult = await pool.query(transactionQuery, [
        reference,
        user_id,
      ]);

      if (transactionResult.rows.length === 0) {
        return res
          .status(404)
          .json({ success: false, message: "Transaction not found" });
      }

      const transaction = transactionResult.rows[0];

      return res.status(200).json({
        success: true,
        data: {
          transaction_id: transaction.transaction_id,
          reference: reference,
          amount: transaction.send_amount,
          currency: transaction.source_currency,
          status: verificationResponse.status,
          paid_at: verificationResponse.paid_at,
          channel: verificationResponse.channel,
          description: transaction.description,
        },
      });
    } catch (error) {
      console.error("Get Transaction Status Error:", error);
      return res
        .status(500)
        .json({ success: false, message: "Failed to get transaction status" });
    }
  },
);

module.exports = router;
