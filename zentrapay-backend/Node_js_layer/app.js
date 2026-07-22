const express = require("express");
const cors = require("cors");
const app = express();
const helmet = require("helmet");
const morgan = require("morgan");
const rateLimit = require("express-rate-limit");
const config = require("./config/database");
const { errorHandler } = require("./middleware/errorHandler");
// const { createProxyMiddleware } = require("http-proxy-middleware");

// ENDPOINTS ROUTES IMPORTS
const accountsRoutes = require("./routes/accountsRoutes");
const historyRoutes = require("./routes/historyRoutes");
const kycRoutes = require("./routes/kycRoutes");
const notificationsRoutes = require("./routes/notificationsRoutes");
const paymentsRoutes = require("./routes/paymentsRoutes");
const refreshToken = require("./routes/refreshToken");
const reportsRoutes = require("./routes/reportsRoutes");
const settingsRoutes = require("./routes/settingsRoutes");
const supportRoutes = require("./routes/supportRoutes");
const usersRoutes = require("./routes/usersRoutes");

// ZENTRAPAY FEATURE ROUTES
const zpayRoutes = require("./routes/zpayRoutes");
const zbankingRoutes = require("./routes/zbankingRoutes");
const zremitRoutes = require("./routes/zremitRoutes");
const zvoiceRoutes = require("./routes/zvoiceRoutes");
const zinvestRoutes = require("./routes/zinvestRoutes");
const zgrowRoutes = require("./routes/zgrowRoutes");
const payanywhereRoutes = require("./routes/payanywhereRoutes");
const secureRoutes = require("./routes/secureRoutes");

// Security middleware
app.use(helmet());
// 1. Get the string from environment variables
const originString = process.env.ALLOWED_ORIGINS || "";

// 2. Split by comma and trim whitespace to create a clean array
const allowedOrigins = originString.split(",").map((origin) => origin.trim());

// 3. Use in your CORS configuration
app.use(
  cors({
    origin: function (origin, callback) {
      // allow requests with no origin (like mobile apps or curl requests)
      if (!origin) {
        console.log("[CORS] No origin header, allowing request");
        return callback(null, true);
      }

      console.log("[CORS] Checking origin:", origin);
      if (allowedOrigins.includes(origin)) {
        console.log("[CORS] Origin allowed:", origin);
        callback(null, true);
      } else {
        console.log("[CORS] Origin DENIED:", origin);
        callback(new Error("Authentication Denied!"));
      }
    },
    credentials: true,
  }),
);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
});
app.use("/api/", limiter);

// Body parsing middleware
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true, limit: "10mb" }));

// Logging
app.use(morgan("combined"));

app.use((req, res, next) => {
  console.log(`[DEBUG] Incoming Request: ${req.method} ${req.url}`);
  console.log(`[DEBUG] Origin header: ${req.headers.origin || "none"}`);
  if (Object.keys(req.body).length > 0) {
    console.log(`[DEBUG] Body:`, JSON.stringify(req.body));
  }
  next();
});

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({ status: "OK", timestamp: new Date().toISOString() });
});

// PAYMENTS ENDPOINTS
app.use("/api/payments", paymentsRoutes);
// USERS ENDPOINTS
app.use("/api/users", usersRoutes); // creating new user account, wallet acccount, currencies accounts, user information
// ACCOUNTS ENDPOINTS
app.use("/api/accounts", accountsRoutes); // wallets, currency accounts, linked banks
// HISTORY AND REPORTING ENDPOINTS
app.use("/api/history", historyRoutes);
app.use("/api/reports", reportsRoutes); // statement, summery
// VERIFICATION AND COMPLIENCE ENDPOINTS
app.use("/api/kyc", kycRoutes); //status, documents, verify
// NOTIFICATION AND PREFERENCES ENDPOINTS
app.use("/api/settings", settingsRoutes);
app.use("/api/notifications", notificationsRoutes);
// UTILITIES AND SUPPORT ENDPOINTS
app.use("/api/support", supportRoutes); //supported banks, customer support, ai assistence, fraud detection, voice recordings
app.use("/api/refreshToken", refreshToken);

// ZENTRAPAY FEATURE ENDPOINTS
app.use("/api/zpay", zpayRoutes); // wallet, cards, NFC/QR payments, contactless
app.use("/api/zbanking", zbankingRoutes); // savings, loans, budgeting, vault
app.use("/api/zremit", zremitRoutes); // cross-border transfers, exchange rates
app.use("/api/zvoice", zvoiceRoutes); // voice commands, voice fraud alerts
app.use("/api/zinvest", zinvestRoutes); // investments, portfolio, AI recommendations
app.use("/api/zgrow", zgrowRoutes); // financial wellness, challenges, rewards
app.use("/api/payanywhere", payanywhereRoutes); // QR payments, merchant, offline
app.use("/api/secure", secureRoutes); // security, biometric, fraud protection

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: "Route not found" });
});

// Error handling middleware
app.use(errorHandler);

module.exports = app;
