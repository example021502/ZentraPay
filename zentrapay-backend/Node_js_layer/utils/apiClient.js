const axios = require("axios");
const https = require("https");

// Create the agent with validation disabled
const httpsAgent = new https.Agent({
  rejectUnauthorized: false,
});

const apiClient = axios.create({
  baseURL: process.env.SPRING_BOOT_BASE_URL || "https://10.46.34.125:2000",
  // Force the use of the insecure agent
  httpsAgent: httpsAgent,
  headers: {
    "Content-Type": "application/json",
    "X-Internal-Secret": process.env.SPRING_BOOT_SECRET_KEY,
  },
});

module.exports = apiClient;
