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
      if (!origin) return callback(null, true);

      if (allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
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

app.use((req, res, next) => {
  console.log(`RECEIVED THE REQUEST FOR:: ${req.originalUrl}`);
  next();
});

// Logging
app.use(morgan("combined"));

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

// 404 handler
app.use((req, res) => {
  res.status(404).json({ success: false, message: "Route not found" });
});

// Error handling middleware
app.use(errorHandler);

module.exports = app;
