const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const RemittanceService = require("../services/remittanceService");
const uuid = require("uuid");
const apiClient = require("../utils/apiClient");

// ========================================================================
// REMITTANCE ROUTES - API DOCUMENTATION FOR FRONTEND
// ========================================================================
//
// All endpoints require authentication via the authenticateToken middleware.
// The middleware validates JWT tokens and attaches userId, email to req.
//
// Base URL: /api/remittance
//
// ENDPOINTS:
// 1. POST /api/remittance/transfer - Cross-border remittance transfer via OnAfriq
//
// GATEWAY ROUTING (handled by Spring Boot OnAfriqGateway):
// - All cross-border remittances use OnAfriq as the primary gateway
// - OnAfriq handles currency conversion and international payout routing
// ========================================================================

/**
 * CROSS-BORDER REMITTANCE TRANSFER
 * =================================
 *
 * Endpoint: POST /api/remittance/transfer
 *
 * Purpose: Send money across borders with currency conversion using OnAfriq.
 *          Supports both bank and mobile money payout methods.
 *
 * Request Body (JSON):
 * {
 *   "sourceTransaction": {
 *     "sourceAmount": "500.00",
 *     "sourceCurrencyCode": "USD",
 *     "destinationAmount": "7725.00",
 *     "destinationCurrencyCode": "GHS",
 *     "payoutOption": "bank" | "momo"
 *   },
 *   "recipientDetails": {
 *     "receiverFirstname": "John",
 *     "receiverLastName": "Doe"
 *   },
 *   "payoutMethod": "bank" | "momo",
 *   "destinationDetails": {
 *     "bankId": "BANK_GCB_GH",
 *     "accountNumber": "1234567890"
 *   } | {
 *     "mobileNetworkCode": "MOMO_MTN_GH",
 *     "phoneNumber": "+233241234567"
 *   },
 *   "transactionPin": "1234"
 * }
 *
 * Required Fields: sourceTransaction, recipientDetails, payoutMethod, destinationDetails, transactionPin
 *
 * Response (Success - 200):
 * {
 *   "success": true,
 *   "result": {
 *     "transactionId": "UUID-string",
 *     "status": "PENDING" | "SUCCESSFUL" | "FAILED",
 *     "sourceAmount": 500.00,
 *     "sourceCurrency": "USD",
 *     "destinationAmount": 7725.00,
 *     "destinationCurrency": "GHS",
 *     "exchangeRate": 15.45,
 *     "fee": 0.00,
 *     "totalCharged": 500.00,
 *     "gatewayName": "OnAfriq",
 *     "authorizationUrl": null,
 *     "accessCode": null,
 *     "expiresAt": "2024-01-15T10:30:00.123Z",
 *     "createdAt": "2024-01-15T10:30:00.123Z"
 *   }
 * }
 *
 * Response (Error - 400/500):
 * {
 *   "success": false,
 *   "message": "Error description"
 * }
 */
// ========================================================================

router.post("/transfer", authenticateToken, async (req, res) => {
  const userId = req.userId;
  const email = req.email;
  if (!userId || !email) {
    return res.json({ success: false, message: "User Error." });
  }

  const {
    sourceTransaction,
    recipientDetails,
    payoutMethod,
    destinationDetails,
    transactionPin,
  } = req.body;

  // Validate required fields
  if (
    !sourceTransaction ||
    !recipientDetails ||
    !payoutMethod ||
    !destinationDetails ||
    !transactionPin
  ) {
    return res.status(400).json({
      success: false,
      message: "Validation Error: Missing required fields",
    });
  }
  console.log("=".repeat(50));
  console.log("sourceTransaction::", sourceTransaction);
  console.log("recipientDetails::", recipientDetails);
  console.log("payoutMethod::", payoutMethod);
  console.log("destinationDetails::", destinationDetails);
  console.log("transactionPin::", transactionPin);
  console.log("=".repeat(50));
  try {
    // Generate unique transaction reference
    const transactionReference =
      "REM-" + uuid.randomUUID().toString().substring(0, 8).toUpperCase();

    // Prepare transfer data
    const payload = {
      user_id: user_id,
      email: email,
      transactionReference: transactionReference,
      sourceTransaction: sourceTransaction,
      recipientDetails: recipientDetails,
      payoutMethod: payoutMethod,
      destinationDetails: destinationDetails,
      transactionPin: transactionPin,
    };

    // Initiate transfer through service
    const result = await apiClient.post("/api/remittance/transfer", payload);
    if (result.data && result.data.success) {
      return res.status(200).json({
        success: true,
        message: result.data.message,
        data: result.data.data,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.message,
        error: result.error,
      });
    }
  } catch (error) {
    console.error("[RemittanceRoutes] Transfer error:", error);
    return res.status(500).json({
      success: false,
      message: "Network or Server Error!",
      error: error.message,
    });
  }
});

module.exports = router;
