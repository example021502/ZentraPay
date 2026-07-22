const express = require("express");
const router = express.Router();
const pool = require("../config/database");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const crypto = require("crypto");
const { authenticateToken } = require("../middleware/authMiddleware");

// GET /api/users
router.get("/", authenticateToken, async (req, res) => {
  try {
    const result = await pool.query(
      "SELECT * FROM users ORDER BY created_at DESC",
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
