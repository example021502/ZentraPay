/**
 * Payment Routes - Multi-Rail Payment API Endpoints
 *
 * This module handles all payment-related API endpoints:
 * - Payment initialization
 * - Transaction verification
 * - Payment status checks
 * - Rail health monitoring
 *
 * @description RESTful API for payment operations across all rails
 * @version 1.0.0
 * @author ZentraPay Team
 */

const express = require("express");
const router = express.Router();
const TransactionService = require("../services/transactionService");
const PaymentRouter = require("../services/paymentRouter");
const { authenticateToken } = require("../middleware/authMiddleware");

// ============================================
// Payment Initialization
// ============================================

/**
 * @route   POST /api/payments/initiate
 * @desc    Initiate a new payment transaction
 * @access  Private
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
// Transaction Management
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
// Transaction History
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
// Rail Information
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
// Statistics (Admin)
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
