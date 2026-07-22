const express = require("express");
const router = express.Router();
const pool = require("../config/database");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const bcrypt = require("bcrypt");
// Import the built-in crypto module to handle the SHA-256 pre-hash execution
const crypto = require("crypto");
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");
{
  /*
  ===============================================
  USER INFORMATION ROUTER
  ===============================================
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
  ===============================================
  LOGIN ROUTER
  ===============================================
  */
}
router.post("/login", async (req, res) => {
  console.log("[NODE_LOGIN] Received login request");
  console.log("[NODE_LOGIN] Headers:", JSON.stringify(req.headers));
  console.log("[NODE_LOGIN] Body:", JSON.stringify(req.body));
  const { email, phone_number, password } = req.body;

  // Defensive Check: Ensure pin is provided right at the beginning
  if (!password || (!email && !phone_number)) {
    return res.json({
      success: false,
      message: "Missing Email/Phone number and Password!",
    });
  }

  try {
    const login = await apiClient.post(`/api/users/login`, {
      email: email,
      phoneNumber: phone_number,
      password: password,
    });
    console.log("[SPRING_LOGIN] httpStatus:", login.status);
    console.log("[SPRING_LOGIN] data:", JSON.stringify(login.data));
    const data = login.data;
    if (data && data.success && data.data) {
      return res.json({
        success: data.success,
        message: data.message,
        data: {
          token: data.data.token,
          fullName: data.data.fullName,
          email: data.data.email,
          zentag: data.data.zentag,
        },
      });
    } else {
      return res.json({
        success: data ? data.success : false,
        message: data
          ? data.message || "Something went wrong, try again!"
          : "Empty response from provider",
      });
    }
  } catch (error) {
    console.error("ERROR::", error);
    return res.json({
      success: error.response.data.success ?? false,
      message:
        error.response.data.message ?? "Login Error! No response from provider",
    });
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
  console.log("[NODE_REGISTER] Received register request");
  console.log("[NODE_REGISTER] Headers:", JSON.stringify(req.headers));
  console.log("[NODE_REGISTER] Body:", JSON.stringify(req.body));
  const { full_name, email, phone_number, password, pin, country } = req.body;

  // Defensive Check: Ensure pin is provided right at the beginning
  if (!full_name || !email || !password || !phone_number || !pin) {
    return res.json({
      success: false,
      message: "Missing value(s)!",
    });
  }

  const zentag = `${email.split("@")[0].trim()}@zentrapay`;

  try {
    const newUser = await apiClient.post(`/api/users/register`, {
      fullName: full_name,
      phoneNumber: phone_number,
      email: email,
      country: country,
      password: password,
      zentag: zentag,
      pin: pin,
    });

    const data = newUser.data;

    console.log("[SPRING_REGISTER] httpStatus:", newUser.status);
    console.log("[SPRING_REGISTER] data:", JSON.stringify(data));
    if (data && data.success && data.data) {
      return res.json({
        success: data.success,
        message: data.message,
        data: {
          token: data.data.token,
          fullName: data.data.fullName,
          email: data.data.email,
          zentag: data.data.zentag,
        },
      });
    } else {
      console.log(
        "[SPRING_REGISTER] unexpected payload:",
        JSON.stringify(newUser.data),
      );
      return res.json({
        success: false,
        message: data
          ? data.message || "Something went wrong, try again!"
          : "Empty response from provider",
      });
    }
  } catch (err) {
    if (err.response) {
      console.error("[SPRING_REGISTER] providerStatus:", err.response.status);
      console.error(
        "[SPRING_REGISTER] providerHeaders:",
        JSON.stringify(err.response.headers),
      );
      console.error(
        "[SPRING_REGISTER] providerData:",
        JSON.stringify(err.response.data),
      );
      const springMessage = err.response?.data?.message;
      return res.json({
        success: false,
        message:
          springMessage ||
          "Registering Error! Provider status " + err.response.status,
      });
    }
    if (err.request) {
      console.error("[SPRING_REGISTER] noResponse:", err.message);
      return res.json({
        success: false,
        message: "Registering Error! No response from provider",
      });
    }
    console.error("[SPRING_REGISTER] unexpected:", err.message);
    res.json({ success: false, message: "Registering Error! try again" });
  }
});

{
  /*
  ===============================================
  PIN CONFIRMATION ROUTER
  ===============================================
  */
}
router.get("/authorization", async (req, res) => {
  const user_id = req.userId;
  const { pin } = req.body;
  if (!pin) {
    return res.json({
      success: false,
      message: "User Error!",
    });
  }
  try {
    const user = await pool.query("SELECT pin FROM users WHERE user_id = $1", [
      user_id,
    ]);
    if (user.rowCount === 0) {
      return res.json({
        success: false,
        message: "User Not found.",
      });
    }
    const pepperedPinHash = crypto
      .createHmac("sha256", pinPepper)
      .update(pin)
      .digest("hex");

    const isValidPin = await bcrypt.compare(pepperedPinHash, user.rows[0].pin);

    if (!isValidPin) {
      return res.json({
        success: false,
        message: "Invalid PIN!",
      });
    }

    res.json({
      success: true,
      message: "PIN verified!",
    });
  } catch (e) {
    console.log("ERROR:: ", e);
    res.json({ success: false, message: "Database Error!" });
  }
});
module.exports = router;
