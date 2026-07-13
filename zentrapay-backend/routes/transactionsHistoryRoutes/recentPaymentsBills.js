const express = require("express");
const router = express.Router();
const pool = require("../../config/db");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../.env") });
const { authenticateToken } = require("../../middleware/authMiddleware");

router.get("/", authenticateToken, async (req, res) => {
  // Extract user_id from the authenticated token payload
  const user_id = req.user?.user_id;

  if (!user_id) {
    return res
      .status(400)
      .json({ success: false, error: "User ID is required." });
  }

  const n_historyQuery =
    "SELECT receiver_id, created_at FROM national_transactions WHERE sender_id = $1";
  const i_historyQuery =
    "SELECT receiver_id, created_at FROM international_transactions WHERE sender_id = $1";
  const bills_query = "SELECT * FROM bills WHERE user_id = $1";

  try {
    // Fetch initial transaction data
    const [n_historyResult, i_historyResult, billsResult] = await Promise.all([
      pool.query(n_historyQuery, [user_id]),
      pool.query(i_historyQuery, [user_id]),
      pool.query(bills_query, [user_id]),
    ]);

    const nationalTx = n_historyResult.rows;
    const internationalTx = i_historyResult.rows;

    // Extract all unique receiver IDs across both transaction types
    const allReceiverIds = [
      ...new Set([
        ...nationalTx.map((tx) => tx.receiver_id),
        ...internationalTx.map((tx) => tx.receiver_id),
      ]),
    ].filter(Boolean); // Filter out any null/undefined IDs

    let contactMap = {};

    if (allReceiverIds.length > 0) {
      // Query users, banks, and bill providers in parallel using the ANY($1) syntax for array matching
      const [usersResult, banksResult, providersResult] = await Promise.all([
        pool.query(
          "SELECT id, name, email, phone FROM users WHERE id = ANY($1)",
          [allReceiverIds],
        ),
        pool.query(
          "SELECT id, bank_name AS name, contact_number AS phone FROM banks WHERE id = ANY($1)",
          [allReceiverIds],
        ),
        pool.query(
          "SELECT id, provider_name AS name, support_email AS email FROM bill_providers WHERE id = ANY($1)",
          [allReceiverIds],
        ),
      ]);

      // Merge all retrieved entities into a single lookup map keyed by ID
      usersResult.rows.forEach((u) => {
        contactMap[u.id] = { ...u, type: "user" };
      });
      banksResult.rows.forEach((b) => {
        contactMap[b.id] = { ...b, type: "bank" };
      });
      providersResult.rows.forEach((p) => {
        contactMap[p.id] = { ...p, type: "provider" };
      });
    }

    // Map contact details directly onto the transaction records
    const nationalWithContacts = nationalTx.map((tx) => ({
      ...tx,
      receiver_details: contactMap[tx.receiver_id] || null,
    }));

    const internationalWithContacts = internationalTx.map((tx) => ({
      ...tx,
      receiver_details: contactMap[tx.receiver_id] || null,
    }));

    return res.json({
      success: true,
      national: nationalWithContacts,
      international: internationalWithContacts,
      bills: billsResult.rows,
    });
  } catch (err) {
    console.error("Error fetching transactions:", err);
    return res.status(500).json({
      success: false,
      status: 500,
      error: "Database Error!",
    });
  }
});

module.exports = router;
