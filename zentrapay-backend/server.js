const path = require("path");

// Combines the current directory path with the relative location of your file
require("dotenv").config({
  path: path.resolve(__dirname, "../.env"),
});
const express = require("express");
const app = express();
const userRoutes = require("./routes/userRoutes");
const loginRoute = require("./routes/login");
const registeringRoute = require("./routes/registering");
const getBalanceRoute = require("./routes/getBalances");
const newWalletRoute = require("./routes/newWalletAccount");
const refreshToken = require("./routes/refreshToken");
const searchContactsRoute = require("./routes/searchContacts/searchContacts");
const getBillProvidersRoute = require("./routes/billProviders/billProviders");
const paymentsRoute = require("./routes/payments/nationalPayments");
const recentPaymentsBillsRoute = require("./routes/transactionsHistoryRoutes/recentPaymentsBills");
const authenticaitonRoute = require("./routes/authentication");
const historyRoute = require("./routes/transactionsHistoryRoutes/history");
const aiAssistanceRoute = require("./routes/aiAssistance");
const converterRoute = require("./routes/converter");
const milestonesRoute = require("./routes/milestones");
const profileRoute = require("./routes/profile");
const liquidityHubRoute = require("./routes/liquidityHub");
const voiceRecordingRoute = require("./routes/voiceRecording");
const settingsRoute = require("./routes/settings");
const fraudDetectionRoute = require("./routes/fraudDetection");
const externalPaymentsRoute = require("./routes/externalPayments");
const bankTransferRoute = require("./routes/payments/bankTransfer");
const newCardRoute = require("./routes/newCard");
const multiRailPaymentsRoute = require("./routes/payments");
const webhooksRoute = require("./routes/webhooks");
const bankAccountsController = require("./routes/bankAccountsRoutes/bankAccountController");
const { authenticateToken } = require("./middleware/authMiddleware");

const cors = require("cors");

app.use(cors());

// Parse incoming application/json requests
app.use(express.json());

// Request logger for local debugging
app.use((req, res, next) => {
  console.log(`[${req.method}] ${req.url}`);
  next();
});

// PAYSTACK SUPPORTED BANK INFORMATION
app.use("/api/bankAccounts", bankAccountsController);

// getting all the bill providers
app.use("api/billProviders", getBillProvidersRoute);

// Public routes (no authentication required)
app.use("/api/login", loginRoute);
app.use("/api/register", registeringRoute);

// Protected routes (authentication required)
app.use("/api/users", userRoutes);
app.use("/api/profile", profileRoute);
app.use("/api/settings", settingsRoute);
app.use("/api/ai", aiAssistanceRoute);
app.use("/api/converter", converterRoute);
app.use("/api/milestones", milestonesRoute);
app.use("/api/liquidity", liquidityHubRoute);
app.use("/api/voice", voiceRecordingRoute);
app.use("/api/fraud", fraudDetectionRoute);

app.use("/api/payments/external", externalPaymentsRoute);
app.use("/api/authentication", authenticaitonRoute);
app.use("/api/history", historyRoute);
app.use("/api/newAccount", newWalletRoute);
app.use("/api/newCard", newCardRoute);
app.use("/api/getBalances", getBalanceRoute);
app.use("/api/searchContacts", searchContactsRoute);
app.use("/api/getRecentPaymentsBills", recentPaymentsBillsRoute);
app.use("/api/payments/national/internal", paymentsRoute);
app.use("/api/refreshToken", refreshToken);

// ============================================
// BANK PAYMENTS ROUTES
// ============================================
app.use("/api/payment/bankTransfer", bankTransferRoute);

// ============================================
// MULTI-RAIL PAYMENT ROUTES
// ============================================
app.use("/api/payments", multiRailPaymentsRoute);

// ============================================
// WEBHOOK ROUTES (Public - signature verified)
// ============================================
app.use("/api/webhooks", webhooksRoute);

// Fallback 404 handler
app.use((req, res) => {
  res.status(404).json({ error: "Endpoint not found" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server active on port ${PORT}`));
