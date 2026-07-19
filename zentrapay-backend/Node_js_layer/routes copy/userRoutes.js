const express = require("express");
const router = express.Router();
const pool = require("../config/database");
const { authenticateToken } = require("../middleware/authMiddleware");
const bcrypt = require("bcrypt");

{
  /*
  GET USER INFORMATION ENDPOINT
  */
}
router.get("/info", authenticateToken, async (req, res) => {
  const user_id = req.userId;
  try {
    const user = await pool.query("SELECT * FROM users WHERE user_id = $1");
    res.json({
      success: true,
      result: user.rows[0],
    });
  } catch (e) {
    console.log("ERROR:: ", e);
    res.json({ success: false, message: "Database Error!" });
  }
});

{
  /*
  REGISTER ENDPOINT
  */
}
router.get("/register", async (req, res) => {
  const user_id = req.userId;
  try {
    const user = await pool.query("SELECT * FROM users WHERE user_id = $1");
    res.json({
      success: true,
      result: user.rows[0],
    });
  } catch (e) {
    console.log("ERROR:: ", e);
    res.json({ success: false, message: "Database Error!" });
  }
});

{
  /*
  LOGIN ENDPOINT
  */
}
router.get("/login", async (req, res) => {
  const user_id = req.userId;
  try {
    const user = await pool.query("SELECT * FROM users WHERE user_id = $1");
    res.json({
      success: true,
      result: user.rows[0],
    });
  } catch (e) {
    console.log("ERROR:: ", e);
    res.json({ success: false, message: "Database Error!" });
  }
});

{
  /*
  PIN CONFIRMATION ENDPOINT
  */
}
router.get("/authorization", authenticateToken, async (req, res) => {
  const user_id = req.userId;
  const { pin } = req.body;
  try {
    const user = await pool.query("SELECT pin FROM users WHERE user_id = $1");
    if (user.rowCount === 0) {
      res.json({
        success: false,
        message: "User not found!",
      });
    }
    const pinPepper = process.env.PIN_PEPPER;
    const 
    const isValidPin = bcrypt.compare(hashedPin, user.rows[0].pin);
    if (isValidPin) {
      res.json({
        success: false,
        message: "User not found!",
      });
    }

    res.json({
      success: true,
      result: user.rows[0],
    });
  } catch (e) {
    console.log("ERROR:: ", e);
    res.json({ success: false, message: "Database Error!" });
  }
});

module.exports = router;
