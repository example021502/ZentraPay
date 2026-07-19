const express = require("express");
const router = express.Router();
const pool = require("../config/database");
const jwt = require("jsonwebtoken");
const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const axios = require("axios");
const https = require("https");
// Create the client
const springClient = axios.create({
  baseURL: process.env.SPRING_BOOT_BASE_URL,
  httpsAgent: new https.Agent({ rejectUnauthorized: false }), // For local dev
});

{
  /*
  COLLECTION END POINT
  */
}
router.get("/collect", async (req, res) => {
  try {
    const data = await springClient.get("/test/hello");
    return res.json({
      success: true,
      message: data.data || "request went through but something went wrong",
    });
  } catch (error) {
    // Extract only the message or specific properties
    console.log("ERROR::", error);
    res.status(500).json({
      success: false,
      message: "Something went wrong!",
    });
  }
});

{
  /*
  DISBURSEMENT END POINT
  */
}
router.get("/disburse", async (req, res) => {
  try {
    const data = await springClient.get("/test/hello");
    return res.json({
      success: true,
      message: data.data || "request went through but something went wrong",
    });
  } catch (error) {
    // Extract only the message or specific properties
    console.log("ERROR::", error);
    res.status(500).json({
      success: false,
      message: "Something went wrong!",
    });
  }
});

{
  /*
  VERIFICATION END POINT
  */
}
router.get("/verify", async (req, res) => {
  try {
    const data = await springClient.get("/test/hello");
    return res.json({
      success: true,
      message: data.data || "request went through but something went wrong",
    });
  } catch (error) {
    // Extract only the message or specific properties
    console.log("ERROR::", error);
    res.status(500).json({
      success: false,
      message: "Something went wrong!",
    });
  }
});

{
  /*
  HISTORY END POINT
  */
}
router.get("/history", async (req, res) => {
  try {
    const data = await springClient.get("/test/hello");
    return res.json({
      success: true,
      message: data.data || "request went through but something went wrong",
    });
  } catch (error) {
    // Extract only the message or specific properties
    console.log("ERROR::", error);
    res.status(500).json({
      success: false,
      message: "Something went wrong!",
    });
  }
});

module.exports = router;
