const express = require("express");
const { authenticateToken } = require("../middleware/authMiddleware");
const router = express.Router();

// GET /api/profile/user - Get user profile
router.get("/profile", authenticateToken, async (req, res) => {
  const user_id = req.userIda;
  if (!user_id) {
    return res.json({ success: false, message: "Error: User id missing!" });
  }
  try {
    const userQuery =
      "SELECT full_name, email, country, zentag, phone_number, FROM users WHERE user_id = $1";
    const userInfo = await pool.query(userQuery, [user_id]);
    if (userInfo.rowCount == 0) {
      return res.json({ success: false, message: "User not found!" });
    }
    return res.json({
      success: true,
      result: userInfo.rows[0],
    });
  } catch (error) {
    console.log("ERROR: ", error);
    res.status(500).json({ success: false, message: "Database Error!" });
  }
});

// GET /api/profile/wallet - Get wallet information
router.get("/wallet", (req, res) => {
  try {
    const wallet = {
      type: "GHS Wallet",
      currency: "GHS",
      balance: 12500.5,
      accountNumber: "johnwillis5623.GHS@zentrapay",
    };

    res.json(wallet);
  } catch (error) {
    res.status(500).json({ error: "Failed to load wallet info" });
  }
});

// GET /api/profile/banks - Get linked bank accounts
router.get("/banks", (req, res) => {
  try {
    const banks = [
      {
        id: 1,
        name: "Ecobank Ghana PLC",
        accountType: "Savings",
        balance: 50000.0,
        dateLinked: "2026-06-06",
        rate: "14.5%",
      },
    ];

    res.json(banks);
  } catch (error) {
    res.status(500).json({ error: "Failed to load linked banks" });
  }
});

// POST /api/profile/qr/generate - Generate QR code
router.post("/qr/generate", (req, res) => {
  try {
    const qrCode = {
      id: Date.now(),
      data: "johnwillis5623.GHS@zentrapay",
      imageUrl:
        "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=johnwillis5623.GHS@zentrapay",
    };

    res.json(qrCode);
  } catch (error) {
    res.status(500).json({ error: "Failed to generate QR code" });
  }
});

module.exports = router;
