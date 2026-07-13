const express = require("express");
const router = express.Router();
const pool = require("../../config/db");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../../.env") });
const { authenticateToken } = require("../../middleware/authMiddleware");

// GET /api/search?query=xyz
router.get("/", authenticateToken, async (req, res) => {
  const user_id = req.user?.user_id;
  const { query } = req.query; // Extract search token from URL parameters

  if (!user_id) {
    return res.json({ success: false, error: "User ID is required." });
  }

  if (!query || query.trim() === "") {
    return res.json({
      success: false,
      error: "Search query string cannot be empty.",
    });
  }

  // Format search term for SQL ILIKE pattern matching (e.g., "%peter%")
  const searchPattern = `%${query.trim()}%`;

  // 1. Search other users/contacts by zentag, name, email, or phone
  const usersSearchQuery = `
    SELECT user_id, zentag, full_name, email, phone_number
    FROM users
    WHERE user_id != $1 AND (
      zentag ILIKE $2 OR
      full_name ILIKE $2 OR
      email ILIKE $2 OR
      phone_number ILIKE $2
    )
    LIMIT 10;
  `;

  // 2. Search user's linked bills by provider name, category, or their custom nickname
  const billsSearchQuery = `
    SELECT provider_id, provider_name, provider_category, customer_account_reference, custom_nickname
    FROM bills
    WHERE user_id = $1 AND (
      provider_name ILIKE $2 OR
      provider_category ILIKE $2 OR
      custom_nickname ILIKE $2
    )
    LIMIT 10;
  `;

  // 3. Search user's linked external bank configurations
  const banksSearchQuery = `
    SELECT id, institution_name, account_name, mask_account_number
    FROM linked_bank_accounts
    WHERE user_id = $1 AND (
      institution_name ILIKE $2 OR
      account_name ILIKE $2
    )
    LIMIT 10;
  `;

  try {
    // Execute all queries simultaneously in parallel for optimum speed
    const [usersResult, billsResult, banksResult] = await Promise.all([
      pool.query(usersSearchQuery, [user_id, searchPattern]),
      pool.query(billsSearchQuery, [user_id, searchPattern]),
      pool.query(banksSearchQuery, [user_id, searchPattern]),
    ]);

    // Comment: Map user rows to attach the polymorphic identifier tracking parameters
    const formattedUsers = usersResult.rows.map((user) => ({
      id: user.user_id.toString(),
      name: user.full_name,
      identifier: user.zentag || user.phone_number, // Primary handle for internal routing
      type: "app_user",
      meta: {
        zentag: user.zentag,
        email: user.email,
      },
    }));

    // Comment: Map bill provider rows with a matching structural data contract layout
    const formattedBills = billsResult.rows.map((bill) => ({
      id: bill.provider_id,
      name: bill.provider_name || bill.custom_nickname,
      identifier: bill.customer_account_reference, // The target meter or account code number string
      type: "bill_provider",
      meta: {
        provider_name: bill.provider_name,
        category: bill.provider_category,
      },
    }));

    // Comment: Map external linked bank configurations to fit standard map rules
    const formattedBanks = banksResult.rows.map((bank) => ({
      id: bank.id.toString(),
      name: bank.account_name,
      identifier: bank.mask_account_number, // The masked account payload target property string
      type: "linked_bank",
      meta: {
        institution_name: bank.institution_name,
      },
    }));

    const contacts = [...formattedUsers, ...formattedBills, ...formattedBanks];

    console.log("THE CONTACTS ARE : ", contacts);

    // Comment: Merges all transformed items into one flat array for the Flutter search UI view
    return res.json({
      success: true,
      contacts: contacts,
    });
  } catch (err) {
    console.error("Search Execution Error:", err);
    return res.status(500).json({
      success: false,
      status: 500,
      error: "Database Error occurred during search execution!",
    });
  }
});

module.exports = router;
