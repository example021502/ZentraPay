const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");
const uuid = require("uuid");

// ========================================================================
// PAYMENT ROUTES - API DOCUMENTATION FOR FRONTEND
// ========================================================================
//
// All endpoints require authentication via the authenticateToken middleware.
// The middleware validates JWT tokens and attaches userId to req.userId.
//
// Base URL: /api/payments
//
// ENDPOINTS:
// 1. POST /api/payments/internal     - Internal wallet-to-wallet transfer
// 2. POST /api/payments/disbursement - External disbursement (national/international)
//
// GATEWAY ROUTING (handled by Spring Boot PaymentGatewayFactory):
// - Ghanaian National (GHS)        → Paystack (primary) → Flutterwave (failover)
// - Other National (NGN, KES, etc) → Paystack (primary) → Flutterwave (failover)
// - International                  → Onafriq (primary)   → Flutterwave (failover)
//
// All transactions are recorded atomically within @Transactional boundaries.
// ========================================================================

/**
 * INTERNAL WALLET-TO-WALLET TRANSFER
 * ===================================
 *
 * Endpoint: POST /api/payments/internal
 *
 * Purpose: Transfer funds between two ZentraPay app users' wallets.
 *          No external gateway involved - instant internal transfer.
 *
 * Request Body (JSON):
 * {
 *   "userId": "UUID of sender (from auth token, can also be sent in body)",
 *   "PIN": "User's transaction PIN",
 *   "recipient": {
 *     "phoneNumber": "+234801234567 OR null",
 *     "zentag": "@johndoe OR null"
 *   },
 *   "paymentDetails": {
 *     "amount": 5000.00,
 *     "currencyCode": "NGN"
 *   }
 * }
 *
 * Required Fields: amount, PIN, recipient (phoneNumber OR zentag), currencyCode
 *
 * Response (Success - 200):
 * {
 *   "success": true,
 *   "result": {
 *     "transactionReference": "UUID-string",
 *     "gatewayName": "ZentraPayInternal",
 *     "amount": 5000.00,
 *     "currencyCode": "NGN",
 *     "fee": 0.00,
 *     "totalCharged": 5000.00,
 *     "status": "SUCCESSFUL",
 *     "paymentChannel": "WALLET_TRANSFER",
 *     "authorizationUrl": null,
 *     "accessCode": null,
 *     "expiresAt": "2024-01-15T10:30:00.123Z"
 *   }
 * }
 *
 * Response (Error - 400):
 * {
 *   "success": false,
 *   "message": "Error description"
 * }
 */
// ========================================================================

/**
 * INTERNAL WALLET-TO-WALLET TRANSFER
 * ===================================
 *
 * Transfers funds between two ZentraPay app users' wallets.
 * No external gateway involved - instant internal transfer.
 *
 * @route POST /api/payments/internal
 * @requires Authentication
 *
 * @param {Object} req.body
 * @param {string} req.body.userId - UUID of sender (optional if in JWT)
 * @param {string} req.body.PIN - User's transaction PIN
 * @param {Object} req.body.recipient - Recipient information
 * @param {string} [req.body.recipient.phoneNumber] - Phone number (alternative to zentag)
 * @param {string} [req.body.recipient.zentag] - Zentag username (alternative to phoneNumber)
 * @param {Object} req.body.paymentDetails - Payment details
 * @param {number} req.body.paymentDetails.amount - Amount to transfer
 * @param {string} req.body.paymentDetails.currencyCode - Currency code (e.g., "NGN", "GHS")
 *
 * @returns {Object} result - Transaction details
 * @returns {string} result.transactionReference - Unique transaction ID
 * @returns {string} result.gatewayName - Always "ZentraPayInternal"
 * @returns {number} result.amount - Transfer amount
 * @returns {string} result.currencyCode - Currency code
 * @returns {number} result.fee - Transaction fee (0.00 for internal)
 * @returns {number} result.totalCharged - Total amount deducted
 * @returns {string} result.status - "SUCCESSFUL" or "FAILED"
 * @returns {string} result.paymentChannel - "WALLET_TRANSFER"
 */
router.post("/internal", authenticateToken, async (req, res) => {
  const { amount, pin, phone_number, zentag, currency_code } = req.body;
  const user_id = req.userId;

  // Validate required fields
  if (!amount || !pin || (!phone_number && !zentag) || !currency_code) {
    return res.json({
      success: false,
      message:
        "Value Error: Missing required fields (amount, pin, phone_number/zentag, currency_code)",
    });
  }

  if (!user_id) {
    return res.json({
      success: false,
      message: "User Error: Authentication required",
    });
  }

  // Build request payload for Spring Boot
  const paymentDetails = {
    amount: amount,
    currencyCode: currency_code,
  };

  const recipientDetails = {
    phoneNumber: phone_number,
    zentag: zentag,
  };

  try {
    // Forward request to Spring Boot backend
    const result = apiClient.get(`/api/payments/internal`, {
      userId: user_id,
      PIN: pin,
      recipient: recipientDetails,
      paymentDetails: paymentDetails,
    });

    console.log("[NODE_JS] Internal transfer result: ", result);

    if (result.data && result.data.success) {
      return res.json({
        success: true,
        result: result.data.paymentDetails,
      });
    } else {
      return res.json({
        success: false,
        message: result.data?.message || "Something went wrong",
      });
    }
  } catch (e) {
    console.log("[NODE_JS] ERROR in internal transfer: ", e);
    return res.json({ success: false, message: "Network or Server Error!" });
  }
});

/**
 * OUTBOUND DISBURSEMENT (NATIONAL & INTERNATIONAL)
 * ================================================
 *
 * Endpoint: POST /api/payments/disbursement
 *
 * Purpose: Send money to external recipients (banks, mobile money, etc.).
 *          Supports both national and international disbursements.
 *          The Spring Boot backend automatically selects the optimal gateway.
 *
 * GATEWAY ROUTING LOGIC:
 * - Ghanaian National (GHS)        → Paystack (primary) → Flutterwave (failover)
 * - Other National (NGN, KES, etc) → Paystack (primary) → Flutterwave (failover)
 * - International                  → Onafriq (primary)   → Flutterwave (failover)
 *
 * Request Body (JSON):
 * {
 *   "userId": "UUID of sender",
 *   "pin": "User's transaction PIN",
 *   "recipient": {
 *     "accountName": "John Doe",
 *     "accountNumber": "0123456789",
 *     "bankCode": "058",
 *     "bankName": "GTBank",
 *     "countryCode": "NG",
 *     "email": "john@example.com"
 *   },
 *   "paymentDetails": {
 *     "amount": 10000.00,
 *     "sourceCurrency": "NGN",
 *     "destinationCurrency": "NGN",
 *     "isInternational": false,
 *     "destinationType": "NUBAN",
 *     "narration": "ZentraPay Payout",
 *     "reference": "DISB-XXXXXXXX"
 *   }
 * }
 *
 * Required Fields: amount, pin, recipient, currency_code
 *
 * Response (Success - 200):
 * {
 *   "success": true,
 *   "result": {
 *     "transactionReference": "DISB-XXXXXXXX or gateway reference",
 *     "gatewayName": "Paystack" | "Onafriq" | "Flutterwave",
 *     "amount": 10000.00,
 *     "currencyCode": "NGN",
 *     "fee": 0.00,
 *     "totalCharged": 10000.00,
 *     "status": "SUCCESSFUL" | "PENDING" | "FAILED",
 *     "paymentChannel": "MOBILE_MONEY" | "NUBAN" | "BANK",
 *     "authorizationUrl": null,
 *     "accessCode": null,
 *     "expiresAt": "2024-01-15T10:30:00.123Z"
 *   }
 * }
 *
 * Response (Error - 400):
 * {
 *   "success": false,
 *   "message": "Error description"
 * }
 */
// ========================================================================

/**
 * OUTBOUND DISBURSEMENT (NATIONAL & INTERNATIONAL)
 * ================================================
 *
 * Sends money to external recipients (banks, mobile money, etc.).
 * Supports both national and international disbursements.
 * The Spring Boot backend automatically selects the optimal gateway with failover.
 *
 * @route POST /api/payments/disbursement
 * @requires Authentication
 *
 * @param {Object} req.body
 * @param {string} req.body.userId - UUID of sender
 * @param {string} req.body.pin - User's transaction PIN
 * @param {Object} req.body.recipient - Recipient information
 * @param {string} req.body.recipient.accountName - Recipient's full name
 * @param {string} req.body.recipient.accountNumber - Bank/mobile money account number
 * @param {string} req.body.recipient.bankCode - Bank code (e.g., "058" for GTBank)
 * @param {string} [req.body.recipient.bankName] - Bank name
 * @param {string} [req.body.recipient.countryCode] - Country code (e.g., "NG", "GH")
 * @param {string} [req.body.recipient.email] - Recipient email
 * @param {Object} req.body.paymentDetails - Payment details
 * @param {number} req.body.paymentDetails.amount - Amount to send
 * @param {string} req.body.paymentDetails.sourceCurrency - Source currency (e.g., "NGN")
 * @param {string} [req.body.paymentDetails.destinationCurrency] - Destination currency (defaults to sourceCurrency)
 * @param {boolean} [req.body.paymentDetails.isInternational] - true for cross-border, false for national
 * @param {string} [req.body.paymentDetails.destinationType] - "MOBILE_MONEY" | "NUBAN" | "BANK" | "GHIPSS"
 * @param {string} [req.body.paymentDetails.narration] - Payment description
 * @param {string} [req.body.paymentDetails.reference] - Custom reference (auto-generated if not provided)
 *
 * @returns {Object} result - Transaction details
 * @returns {string} result.transactionReference - Unique transaction ID
 * @returns {string} result.gatewayName - Gateway used (Paystack/Onafriq/Flutterwave)
 * @returns {number} result.amount - Sent amount
 * @returns {string} result.currencyCode - Currency code
 * @returns {number} result.fee - Transaction fee
 * @returns {number} result.totalCharged - Total amount charged
 * @returns {string} result.status - "SUCCESSFUL" | "PENDING" | "FAILED"
 * @returns {string} result.paymentChannel - Payment channel type
 */
router.post("/disbursement", authenticateToken, async (req, res) => {
  const {
    amount,
    pin,
    phone_number,
    zentag,
    currency_code,
    destination_currency,
    is_international,
    destination_type,
    recipient,
    narration,
  } = req.body;
  const user_id = req.userId;
  const email = req.email;

  // Validate required fields
  if (!amount || !pin || (!phone_number && !zentag) || !currency_code) {
    return res.status(400).json({
      success: false,
      message:
        "Validation Error: Missing required fields (amount, pin, phone_number/zentag, currency_code)",
    });
  }

  if (!recipient) {
    return res.status(400).json({
      success: false,
      message: "Validation Error: Recipient details are required",
    });
  }

  if (!user_id || !email) {
    return res
      .status(401)
      .json({ success: false, message: "Error: User identification error!" });
  }

  // Generate unique reference for this disbursement
  const reference =
    "DISB-" + uuid.randomUUID().toString().substring(0, 8).toUpperCase();

  // Build payment details object
  const paymentDetails = {
    amount: amount,
    sourceCurrency: currency_code,
    destinationCurrency: destination_currency || currency_code,
    isInternational: is_international || false,
    destinationType: destination_type || "MOBILE_MONEY",
    narration: narration || "ZentraPay Disbursement Payout",
    reference: reference,
  };

  try {
    // Build payload for Spring Boot
    const payload = {
      user_id: user_id,
      email: email,
      pin: pin,
      recipient: recipient,
      paymentDetails: paymentDetails,
    };

    console.log(
      "[NODE_JS] Routing disbursement to Spring Boot: userId=%s, amount=%s %s, international=%s, gateway=%s",
      user_id,
      email,
      amount,
      currency_code,
      is_international ? "YES" : "NO",
      is_international ? "Onafriq (primary)" : "Paystack (primary)",
    );

    // Forward to Spring Boot backend
    const response = await apiClient.post(
      "/api/payments/disbursement",
      payload,
    );

    const result = response.data;

    console.log("[NODE_JS] Disbursement result: ", result);

    if (result && result.success) {
      return res.json({
        success: true,
        result: result.paymentDetails,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.message || "Something went wrong",
      });
    }
  } catch (e) {
    console.error(
      "[NODE_JS] ERROR processing disbursement: ",
      e?.response?.data || e.message,
    );
    return res
      .status(500)
      .json({ success: false, message: "Network or Server Error!" });
  }
});

module.exports = router;
