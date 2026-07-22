const path = require("path");
const axios = require("axios");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

// Initialize axios instance for PayStack API calls
const paystackClient = axios.create({
  baseURL: process.env.PAYSTACK_BASE_API,
  headers: {
    Authorization: `Bearer ${process.env.PAYSTACK_TEST_SK}`,
    "Content-Type": "application/json",
  },
});
// Initialize axios instance for onAfriq API calls
const onAfriqClient = axios.create({
  baseURL: process.env.ONAFRIQ_BASE_API,
  headers: {
    Authorization: `Bearer ${process.env.PAYSTACK_TEST_SK}`,
    "Content-Type": "application/json",
  },
});

const PAYSTACK_ROUTES = [
  // POST REQUEST: Initialize a new payment session and returns a checkout URL or access code
  "/transaction/initialize",

  // GET REQUEST: Check the status of a specific transaction using its reference number
  "/transaction/verify/:reference",

  // POST REQUEST: Register a user's bank account or mobile money details to enable payouts
  "/transferrecipient",

  // POST REQUEST: Move funds from your ZentraPay balance to a registered transfer recipient
  "/transfer",

  // GET REQUEST: Confirm the bank account details of a user before initiating a transfer
  "/bank/resolve",

  // GET REQUEST: Retrieve a list of all banks supported by Paystack in the target country
  "/bank",
];

const ONAFRIQ_ROUTES = [
  // POST REQUEST: Create a new collection request (to pull funds from a customer)
  "/api/v5/collectionrequests",

  // POST REQUEST: Create a new payout (to disburse funds to a mobile wallet or bank account)
  "/api/v5/payouts",

  // GET REQUEST: Retrieve the details of a single payout
  "/api/v5/payouts/:id",

  // GET REQUEST: List all payouts (supports filtering/pagination via query parameters)
  "/api/v5/payouts",

  // GET REQUEST: Check account/phone validation status (if supported by your specific integration)
  "/api/v5/contacts/:id",
];

// Routes that require authentication
const PROTECTED_ROUTES = [
  "/api/users",
  "/api/profile",
  "/api/settings",
  "/api/paystack",
  "/api/payments",
  "/api/history",
  "/api/newWallet",
  "/api/getBalances",
  "/api/searchContacts",
  "/api/billProviders",
  "/api/ai",
  "/api/voice",
  "/api/fraud",
  "/api/authentication",
];

/**
 * Request Interceptor Middleware
 */
const requestInterceptor = (req, res, next) => {
  const requestId = `req_${Date.now()}_${Math.random().toString(36).substring(2, 15)}`;
  req.requestId = requestId;
  req.timestamp = new Date().toISOString();

  const isPayStackRoute = PAYSTACK_ROUTES.some((route) =>
    req.path.startsWith(route),
  );

  req.requestMetadata = {
    type: isPayStackRoute ? "paystack_route" : "app_server_route",
    target: isPayStackRoute ? process.env.PAYSTACK_BASE_API : "app_server",
    requiresAuth: PROTECTED_ROUTES.some((route) => req.path.startsWith(route)),
    originalUrl: req.originalUrl,
    method: req.method,
  };

  if (isPayStackRoute) {
    req.paystackConfig = {
      secretKey: process.env.PAYSTACK_TEST_SK,
      publicKey: process.env.PAYSTACK_TEST_PK,
      baseURL: process.env.PAYSTACK_BASE_API,
    };
  }

  console.log(
    `[${req.timestamp}] [${requestId}] ${req.method} ${req.originalUrl} | ` +
      `Type: ${req.requestMetadata.type} | ` +
      `Auth Required: ${req.requestMetadata.requiresAuth}`,
  );

  next();
};

/**
 * PayStack Request Handler
 */
const payStackProxy = async (req, res, next) => {
  if (req.requestMetadata.type === "paystack_route") {
    try {
      console.log(
        `[${req.timestamp}] [${req.requestId}] Proxying to PayStack API: ${req.method} ${req.path}`,
      );

      // Cleaned up URL handling to prevent double prefixing
      const cleanPath = req.path.replace(/^\/api\/paystack/, "");

      const paystackResponse = await paystackClient({
        method: req.method.toLowerCase(),
        url: cleanPath || "/",
        data: req.body,
        params: req.query,
      });

      res.status(paystackResponse.status).json({
        success: true,
        data: paystackResponse.data.data,
        message: paystackResponse.data.message,
      });
    } catch (error) {
      console.error(
        `[${req.timestamp}] [${req.requestId}] PayStack API Error:`,
        error.response?.data || error.message,
      );

      res.status(error.response?.status || 500).json({
        success: false,
        message: error.response?.data?.message || "PayStack API request failed",
        error: error.response?.data || error.message,
      });
    }
  } else {
    next();
  }
};

/**
 * App Server Request Handler
 */
const appServerHandler = async (req, res, next) => {
  if (req.requestMetadata.type === "app_server_route") {
    console.log(
      `[${req.timestamp}] [${req.requestId}] Processing App Server request: ${req.method} ${req.path}`,
    );

    req.appServerConfig = {
      environment: process.env.NODE_ENV || "development",
      baseUrl: process.env.BASE_URL || `http://localhost:${process.env.PORT}`,
    };

    const microserviceRoutes = {
      "/api/ai": process.env.AI_SERVICE_URL,
      "/api/voice": process.env.VOICE_SERVICE_URL,
      "/api/fraud": process.env.FRAUD_SERVICE_URL,
    };

    const microserviceUrl = Object.entries(microserviceRoutes).find(([route]) =>
      req.path.startsWith(route),
    )?.[1];

    if (microserviceUrl) {
      try {
        console.log(
          `[${req.timestamp}] [${req.requestId}] Proxying to microservice: ${microserviceUrl}`,
        );

        const microserviceResponse = await axios({
          method: req.method,
          url: `${microserviceUrl}${req.path}`,
          data: req.body,
          params: req.query,
          headers: {
            ...req.headers,
            host: new URL(microserviceUrl).host,
          },
        });

        res.status(microserviceResponse.status).json(microserviceResponse.data);
      } catch (error) {
        console.error(
          `[${req.timestamp}] [${req.requestId}] Microservice Error:`,
          error.message,
        );
        res.status(error.response?.status || 500).json({
          success: false,
          message: "Microservice request failed",
          error: error.message,
        });
      }
    } else {
      next();
    }
  } else {
    next();
  }
};

/**
 * Route Validator
 */
const routeValidator = (req, res, next) => {
  if (!req.requestMetadata) {
    return res.status(500).json({
      success: false,
      message: "Request interceptor not properly configured",
      error: "Missing request metadata",
    });
  }

  const validTargets = ["paystack_route", "app_server_route"];
  if (!validTargets.includes(req.requestMetadata.type)) {
    return res.status(400).json({
      success: false,
      message: "Invalid request type",
      type: req.requestMetadata.type,
    });
  }

  next();
};

const getRequestMetadata = (req) => req.requestMetadata || null;
const isPayStackRequest = (req) =>
  req.requestMetadata?.type === "paystack_route";
const requiresAuth = (req) => req.requestMetadata?.requiresAuth || false;

module.exports = {
  requestInterceptor,
  payStackProxy,
  appServerHandler,
  routeValidator,
  getRequestMetadata,
  isPayStackRequest,
  requiresAuth,
  paystackClient, // Exporting this so your application routes can manually call PayStack after checking balances
};
