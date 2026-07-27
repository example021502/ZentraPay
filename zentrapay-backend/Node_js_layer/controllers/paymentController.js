/**
 * Payment Controller - Multi-Rail Payment API Endpoints
 *
 * This module handles ALL payment-related operations:
 * - POST /api/payments/internal     - Internal wallet-to-wallet transfer
 * - POST /api/payments/disbursement - External disbursement (national/international)
 * - POST /api/payments/verify       - Verify transaction status
 * - GET  /api/payments/status/:ref  - Get payment status
 * - POST /api/payments/cancel       - Cancel pending transaction
 * - POST /api/payments/refund       - Refund completed transaction
 * - GET  /api/payments/history      - Get user transaction history
 * - GET  /api/payments/:id          - Get transaction details
 * - GET  /api/payments/rails        - Get available payment rails
 * - GET  /api/payments/rails/:rail/currencies - Get supported currencies
 *
 * ============================================
 * ARCHITECTURE OVERVIEW
 * ============================================
 *
 * 1. Node.js Layer (Port 3000) - AUTHENTICATION & ORCHESTRATION
 *    - Validates JWT tokens
 *    - Extracts user context
 *    - Forwards requests to Spring Boot
 *    - Standardizes responses for frontend
 *
 * 2. Spring Boot Layer (Port 2000) - PAYMENT PROCESSING
 *    - Validates request payload
 *    - Selects optimal payment gateway
 *    - Processes payment via Paystack/Onafriq/Flutterwave
 *    - Records transaction atomically
 *
 * GATEWAY ROUTING (Handled by Spring Boot):
 * - Ghanaian National (GHS)         → Paystack (primary) → Flutterwave (failover)
 * - Other National (NGN, KES, etc)  → Paystack (primary) → Flutterwave (failover)
 * - International                   → Onafriq (primary)   → Flutterwave (failover)
 *
 * ============================================
 * REQUEST/RESPONSE FLOW
 * ============================================
 *
 * Frontend → Node.js → Spring Boot → Payment Gateway
 *           (Auth)     (Process)      (External API)
 *
 * All responses follow this standardized format:
 * {
 *   "success": true/false,
 *   "result": { ... } | "data": { ... },
 *   "message": "Human readable message"
 * }
 */

const express = require("express");
const router = express.Router();
const TransactionService = require("../services/transactionService");
const PaymentRouter = require("../services/paymentRouter");
const { authenticateToken } = require("../middleware/authMiddleware");

// ============================================
// PAYMENT INITIALIZATION
// ============================================

/**
 * @route   POST /api/payments/initiate
 * @desc    Initiate a new payment transaction (for deposit/top-up)
 * @access  Private
 *
 * Request Body:
 * {
 *   "type": "deposit" | "withdrawal" | "transfer",
 *   "amount": 1000.00,
 *   "currency": "GHS",
 *   "recipient": { ... },
 *   "channel": "web" | "mobile" | "ussd",
 *   "description": "Payment description",
 *   "metadata": { ... }
 * }
 */
router.post("/initiate", authenticateToken, async (req, res) => {
  try {
    const {
      type,
      amount,
      currency,
      recipient,
      channel,
      description,
      metadata,
    } = req.body;

    // Validate required fields
    if (!type || !amount || !recipient) {
      return res.status(400).json({
        success: false,
        message: "Type, amount, and recipient are required",
      });
    }

    // Validate amount
    if (amount <= 0) {
      return res.status(400).json({
        success: false,
        message: "Amount must be greater than 0",
      });
    }

    // Create transaction
    const transactionResult = await TransactionService.createTransaction({
      user_id: req.userId || req.user?.id || req.user?.user_id,
      type,
      amount,
      currency: currency || "GHS",
      recipient,
      channel: channel || "web",
      description,
      metadata,
      ip_address: req.ip,
      user_agent: req.get("user-agent"),
    });

    if (!transactionResult.success) {
      return res.status(500).json({
        success: false,
        message: "Failed to create transaction",
        error: transactionResult.error,
      });
    }

    const transaction = transactionResult.data;

    // Process transaction through payment router
    const processResult = await TransactionService.processTransaction(
      transaction.id,
      {
        email: req.user?.email || req.userEmail,
        ...recipient,
      },
    );

    if (!processResult.success) {
      return res.status(400).json({
        success: false,
        message: processResult.message,
        error: processResult.error,
        data: processResult.data,
      });
    }

    return res.status(200).json({
      success: true,
      message: "Payment initiated successfully",
      data: {
        transaction_id: transaction.id,
        reference: transaction.reference,
        rail: transaction.rail,
        payment_url: processResult.data.payment_url,
        ussd_code: processResult.data.ussd_code,
        status: transaction.status,
      },
    });
  } catch (error) {
    console.error("[PaymentRoutes] Initiate payment error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to initiate payment",
      error: error.message,
    });
  }
});

// ============================================
// EXTERNAL DISBURSEMENT
// ============================================

/**
 * @route   POST /api/payments/external
 * @desc    Send money to external recipients (banks, mobile money)
 * @access  Private
 *
 * Request Body:
 * {
 *   "amount": 10000.00,
 *   "pin": "1234",
 *   "recipient": {
 *     "accountName": "John Doe",
 *     "accountNumber": "0123456789",
 *     "bankCode": "058",
 *     "countryCode": "NG"
 *   },
 *   "paymentDetails": {
 *     "sourceCurrency": "NGN",
 *     "destinationCurrency": "NGN",
 *     "isInternational": false,
 *     "destinationType": "NUBAN",
 *     "narration": "Payout"
 *   }
 * }
 */
router.post("/external", authenticateToken, async (req, res) => {
  try {
    const { amount, pin, recipient, paymentDetails } = req.body;

    // Validate required fields
    if (!amount || !pin || !recipient || !paymentDetails) {
      return res.status(400).json({
        success: false,
        message: "Amount, pin, recipient, and paymentDetails are required",
      });
    }

    // Forward to Spring Boot backend
    const response = await apiClient.post("/api/payments/disbursement", {
      user_id: req.userId,
      email: req.email,
      pin: pin,
      recipient: recipient,
      paymentDetails: {
        amount: amount,
        sourceCurrency: paymentDetails.sourceCurrency || "NGN",
        destinationCurrency:
          paymentDetails.destinationCurrency || paymentDetails.sourceCurrency,
        isInternational: paymentDetails.isInternational || false,
        destinationType: paymentDetails.destinationType || "MOBILE_MONEY",
        narration: paymentDetails.narration || "ZentraPay Disbursement",
        reference:
          paymentDetails.reference ||
          "DISB-" + uuid.randomUUID().toString().substring(0, 8).toUpperCase(),
      },
    });

    const result = response.data;

    return res.status(200).json({
      success: true,
      result: result.data || result.paymentDetails,
    });
  } catch (error) {
    console.error("[PaymentRoutes] External payment error:", error);
    return res.status(500).json({
      success: false,
      message:
        error.response?.data?.message || "Failed to process external payment",
      error: error.response?.data || error.message,
    });
  }
});

// ============================================
// TRANSACTION VERIFICATION
// ============================================

/**
 * @route   POST /api/payments/verify
 * @desc    Verify payment transaction status
 * @access  Private
 */
router.post("/verify", authenticateToken, async (req, res) => {
  try {
    const { reference, transaction_id } = req.body;

    if (!reference && !transaction_id) {
      return res.status(400).json({
        success: false,
        message: "Reference or transaction_id is required",
      });
    }

    // Find transaction
    let transaction;
    if (reference) {
      const txnResult =
        await TransactionService.getTransactionByReference(reference);
      if (!txnResult.success) {
        return res.status(404).json({
          success: false,
          message: "Transaction not found",
        });
      }
      transaction = txnResult.data;
    } else {
      const txnResult = await TransactionService.getTransaction(transaction_id);
      if (!txnResult.success) {
        return res.status(404).json({
          success: false,
          message: "Transaction not found",
        });
      }
      transaction = txnResult.data;
    }

    // Verify transaction
    const verifyResult = await TransactionService.verifyTransaction(
      transaction.id,
    );

    return res.status(200).json({
      success: true,
      data: {
        transaction: verifyResult.data,
        verification: verifyResult.verification,
      },
    });
  } catch (error) {
    console.error("[PaymentRoutes] Verify payment error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to verify payment",
      error: error.message,
    });
  }
});

// ============================================
// PAYMENT STATUS
// ============================================

/**
 * @route   GET /api/payments/status/:reference
 * @desc    Get payment status by reference
 * @access  Private
 */
router.get("/status/:reference", authenticateToken, async (req, res) => {
  try {
    const { reference } = req.params;

    const txnResult =
      await TransactionService.getTransactionByReference(reference);
    if (!txnResult.success) {
      return res.status(404).json({
        success: false,
        message: "Transaction not found",
      });
    }

    const transaction = txnResult.data;

    // Verify with provider if transaction is still processing
    let verification = null;
    if (
      transaction.status === "processing" &&
      transaction.rail &&
      transaction.provider_reference
    ) {
      try {
        const verifyResult = await PaymentRouter.verifyTransaction(
          transaction.provider_reference,
          transaction.rail,
        );
        verification = verifyResult;
      } catch (error) {
        console.error("[PaymentRoutes] Verification error:", error);
      }
    }

    return res.status(200).json({
      success: true,
      data: {
        transaction,
        verification,
      },
    });
  } catch (error) {
    console.error("[PaymentRoutes] Get status error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get payment status",
      error: error.message,
    });
  }
});

// ============================================
// TRANSACTION MANAGEMENT
// ============================================

/**
 * @route   POST /api/payments/cancel
 * @desc    Cancel a pending transaction
 * @access  Private
 */
router.post("/cancel", authenticateToken, async (req, res) => {
  try {
    const { transaction_id, reason } = req.body;

    if (!transaction_id) {
      return res.status(400).json({
        success: false,
        message: "Transaction ID is required",
      });
    }

    const result = await TransactionService.cancelTransaction(
      transaction_id,
      reason,
    );

    return res.status(200).json({
      success: result.success,
      message: result.message,
      data: result.data,
    });
  } catch (error) {
    console.error("[PaymentRoutes] Cancel payment error:", error);
    return res.status(500).json({
      success: false,
      message: error.message || "Failed to cancel payment",
    });
  }
});

/**
 * @route   POST /api/payments/refund
 * @desc    Refund a completed transaction
 * @access  Private
 */
router.post("/refund", authenticateToken, async (req, res) => {
  try {
    const { transaction_id, amount, reason } = req.body;

    if (!transaction_id) {
      return res.status(400).json({
        success: false,
        message: "Transaction ID is required",
      });
    }

    const result = await TransactionService.refundTransaction(
      transaction_id,
      amount,
      reason,
    );

    return res.status(200).json({
      success: result.success,
      message: result.message,
      data: result.data,
    });
  } catch (error) {
    console.error("[PaymentRoutes] Refund payment error:", error);
    return res.status(500).json({
      success: false,
      message: error.message || "Failed to refund payment",
    });
  }
});

// ============================================
// TRANSACTION HISTORY
// ============================================

/**
 * @route   GET /api/payments/history
 * @desc    Get user transaction history
 * @access  Private
 */
router.get("/history", authenticateToken, async (req, res) => {
  try {
    const {
      status,
      type,
      rail,
      startDate,
      endDate,
      page = 1,
      limit = 20,
    } = req.query;

    const result = await TransactionService.getUserTransactions(
      req.userId || req.user?.id || req.user?.user_id,
      {
        status,
        type,
        rail,
        startDate,
        endDate,
        page,
        limit,
      },
    );

    return res.status(200).json({
      success: true,
      data: result.data,
      pagination: result.pagination,
    });
  } catch (error) {
    console.error("[PaymentRoutes] Get history error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get transaction history",
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/payments/:transactionId
 * @desc    Get transaction details
 * @access  Private
 */
router.get("/:transactionId", authenticateToken, async (req, res) => {
  try {
    const { transactionId } = req.params;

    const result = await TransactionService.getTransaction(transactionId);

    if (!result.success) {
      return res.status(404).json({
        success: false,
        message: result.message,
      });
    }

    const transaction = result.data;

    // Ensure user can only access their own transactions
    const currentUserId = req.userId || req.user?.id || req.user?.user_id;
    if (transaction.user_id !== currentUserId) {
      return res.status(403).json({
        success: false,
        message: "Access denied",
      });
    }

    return res.status(200).json({
      success: true,
      data: transaction,
    });
  } catch (error) {
    console.error("[PaymentRoutes] Get transaction error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get transaction",
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/payments/:transactionId/history
 * @desc    Get transaction history/audit log
 * @access  Private
 */
router.get("/:transactionId/history", authenticateToken, async (req, res) => {
  try {
    const { transactionId } = req.params;

    const result =
      await TransactionService.getTransactionHistory(transactionId);

    return res.status(200).json({
      success: true,
      data: result.data,
    });
  } catch (error) {
    console.error("[PaymentRoutes] Get transaction history error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get transaction history",
      error: error.message,
    });
  }
});

// ============================================
// PAYMENT RAILS INFO
// ============================================

/**
 * @route   GET /api/payments/rails
 * @desc    Get available payment rails and their status
 * @access  Public
 */
router.get("/rails", async (req, res) => {
  try {
    const healthStatus = PaymentRouter.getHealthStatus();
    const railConfigs = PaymentRouter.getAllRailConfigs();

    return res.status(200).json({
      success: true,
      data: {
        rails: Object.entries(railConfigs).map(([key, config]) => ({
          id: key,
          ...config,
          health: healthStatus.rails[key],
          circuitBreaker: healthStatus.circuitBreakers[key],
        })),
      },
    });
  } catch (error) {
    console.error("[PaymentRoutes] Get rails error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get payment rails",
      error: error.message,
    });
  }
});

/**
 * @route   GET /api/payments/rails/:rail/currencies
 * @desc    Get supported currencies for a rail
 * @access  Public
 */
router.get("/rails/:rail/currencies", async (req, res) => {
  try {
    const { rail } = req.params;
    const currencies = PaymentRouter.getSupportedCurrencies(rail);

    return res.status(200).json({
      success: true,
      data: currencies,
    });
  } catch (error) {
    console.error("[PaymentRoutes] Get currencies error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get supported currencies",
      error: error.message,
    });
  }
});

// ============================================
// STATISTICS (Admin)
// ============================================

/**
 * @route   GET /api/payments/statistics
 * @desc    Get payment statistics
 * @access  Private (Admin)
 */
router.get("/statistics", authenticateToken, async (req, res) => {
  try {
    // TODO: Add admin role check
    // if (req.user.role !== 'admin') {
    //   return res.status(403).json({ success: false, message: 'Access denied' });
    // }

    const { startDate, endDate, userId, rail } = req.query;

    const result = await TransactionService.getTransactionStatistics({
      startDate,
      endDate,
      userId,
      rail,
    });

    return res.status(200).json({
      success: true,
      data: result.data,
    });
  } catch (error) {
    console.error("[PaymentRoutes] Get statistics error:", error);
    return res.status(500).json({
      success: false,
      message: "Failed to get statistics",
      error: error.message,
    });
  }
});

module.exports = router;
