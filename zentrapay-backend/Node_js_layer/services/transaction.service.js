/**
 * Transaction Service - Centralized Transaction Management
 *
 * This service manages all transaction operations across all payment rails:
 * - Transaction creation and tracking
 * - Status monitoring and updates
 * - Transaction history and reporting
 * - Reconciliation and audit logging
 *
 * @description Provides unified transaction management for multi-rail payments
 * @version 1.0.0
 * @author ZentraPay Team
 */

const { v4: uuidv4 } = require("uuid");
const PaymentRouter = require("./paymentRouter");
const dotenv = require("dotenv");

// Import service classes
const PaystackService = require("./paystackService");
const FlutterwaveService = require("./flutterwaveService");
const OnafriqService = require("./onafriqService");
const HubtelService = require("./hubtelService");

// Load environment variables
dotenv.config({ path: require("path").resolve(__dirname, "../.env") });

// ============================================
// Transaction Status Constants
// ============================================

const TRANSACTION_STATUS = {
  PENDING: "pending",
  PROCESSING: "processing",
  SUCCESS: "success",
  FAILED: "failed",
  CANCELLED: "cancelled",
  REFUNDED: "refunded",
  EXPIRED: "expired",
};

const TRANSACTION_TYPES = {
  DOMESTIC_TRANSFER: "domestic_transfer",
  CROSSBORDER_TRANSFER: "crossborder_transfer",
  WALLET_FUNDING: "wallet_funding",
  BANK_PAYOUT: "bank_payout",
  MOBILE_MONEY: "mobile_money",
  USSD_PAYMENT: "ussd_payment",
  BILL_PAYMENT: "bill_payment",
  REFUND: "refund",
};

// ============================================
// Transaction Service Class
// ============================================

class TransactionService {
  constructor() {
    this.paymentRouter = PaymentRouter;
    this.transactions = new Map(); // In-memory storage (replace with database in production)
    this.transactionHistory = new Map();
  }

  // ============================================
  // Transaction Creation
  // ============================================

  /**
   * Create a new transaction
   * @param {Object} transactionData - Transaction details
   * @returns {Promise<Object>} Created transaction
   */
  async createTransaction(transactionData) {
    try {
      const transactionId = uuidv4();
      const reference = this.generateReference(transactionData.type);

      const transaction = {
        id: transactionId,
        reference: reference,
        user_id: transactionData.user_id,
        type: transactionData.type || TRANSACTION_TYPES.DOMESTIC_TRANSFER,
        status: TRANSACTION_STATUS.PENDING,
        amount: transactionData.amount,
        currency: transactionData.currency || "GHS",
        fee: transactionData.fee || 0,
        net_amount: transactionData.amount - (transactionData.fee || 0),
        rail: null, // Will be set by payment router
        provider_reference: null,
        provider_transaction_id: null,
        recipient: transactionData.recipient || {},
        sender: transactionData.sender || {},
        metadata: transactionData.metadata || {},
        description: transactionData.description || "",
        channel: transactionData.channel || "web",
        ip_address: transactionData.ip_address,
        user_agent: transactionData.user_agent,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
        completed_at: null,
        failed_at: null,
        error_message: null,
        webhook_received: false,
        verification_attempts: 0,
        max_verification_attempts: 10,
      };

      // Store transaction
      this.transactions.set(transactionId, transaction);

      // Add to history
      this.addToHistory(transactionId, "created", transaction);

      console.log(
        `[TransactionService] Created transaction: ${transactionId} (${reference})`,
      );

      return {
        success: true,
        data: transaction,
      };
    } catch (error) {
      console.error("[TransactionService] Create transaction error:", error);
      throw error;
    }
  }

  /**
   * Generate unique transaction reference
   * @param {String} type - Transaction type
   * @returns {String} Unique reference
   */
  generateReference(type) {
    const timestamp = Date.now().toString(36).toUpperCase();
    const random = Math.random().toString(36).substring(2, 8).toUpperCase();

    let prefix = "TXN";
    switch (type) {
      case TRANSACTION_TYPES.CROSSBORDER_TRANSFER:
        prefix = "ONA";
        break;
      case TRANSACTION_TYPES.USSD_PAYMENT:
        prefix = "HUB";
        break;
      case TRANSACTION_TYPES.REFUND:
        prefix = "REF";
        break;
      default:
        prefix = "TXN";
    }

    return `${prefix}_${timestamp}_${random}`;
  }

  // ============================================
  // Transaction Processing
  // ============================================

  /**
   * Process transaction through payment router
   * @param {String} transactionId - Transaction ID
   * @param {Object} paymentData - Payment data
   * @returns {Promise<Object>} Processing result
   */
  async processTransaction(transactionId, paymentData) {
    try {
      const transaction = this.transactions.get(transactionId);
      if (!transaction) {
        throw new Error("Transaction not found");
      }

      if (transaction.status !== TRANSACTION_STATUS.PENDING) {
        throw new Error(`Transaction is in ${transaction.status} state`);
      }

      // Update status to processing
      transaction.status = TRANSACTION_STATUS.PROCESSING;
      transaction.updated_at = new Date().toISOString();
      this.addToHistory(transactionId, "processing_started", transaction);

      // Select rail using payment router
      const rail = this.paymentRouter.selectRail({
        type: transaction.type,
        currency: transaction.currency,
        amount: transaction.amount,
        recipientCountry: transaction.recipient?.country,
        channel: transaction.channel,
      });

      transaction.rail = rail;
      this.addToHistory(transactionId, "rail_selected", { rail });

      // Process payment through selected rail
      const paymentResult = await this.paymentRouter.processPayment({
        ...paymentData,
        reference: transaction.reference,
        user_id: transaction.user_id,
        currency: transaction.currency,
        amount: transaction.amount,
      });

      if (paymentResult.success) {
        // Update transaction with provider details
        transaction.provider_reference = paymentResult.data.reference;
        transaction.provider_transaction_id =
          paymentResult.data.flutterwave_reference ||
          paymentResult.data.transfer_id ||
          paymentResult.data.transaction_id;
        transaction.status = TRANSACTION_STATUS.PROCESSING;
        transaction.updated_at = new Date().toISOString();

        this.addToHistory(transactionId, "payment_initiated", {
          rail,
          provider_reference: transaction.provider_reference,
        });

        return {
          success: true,
          data: {
            transaction,
            payment_url: paymentResult.data.authorization_url,
            ussd_code: paymentResult.data.ussd_code,
            reference: transaction.reference,
          },
        };
      } else {
        // Payment initialization failed
        transaction.status = TRANSACTION_STATUS.FAILED;
        transaction.failed_at = new Date().toISOString();
        transaction.error_message = paymentResult.message;
        transaction.updated_at = new Date().toISOString();

        this.addToHistory(transactionId, "payment_failed", {
          error: paymentResult.error,
        });

        return {
          success: false,
          message: paymentResult.message,
          error: paymentResult.error,
          data: transaction,
        };
      }
    } catch (error) {
      console.error("[TransactionService] Process transaction error:", error);
      throw error;
    }
  }

  // ============================================
  // Transaction Verification
  // ============================================

  /**
   * Verify transaction status
   * @param {String} transactionId - Transaction ID
   * @returns {Promise<Object>} Verification result
   */
  async verifyTransaction(transactionId) {
    try {
      const transaction = this.transactions.get(transactionId);
      if (!transaction) {
        throw new Error("Transaction not found");
      }

      if (!transaction.rail || !transaction.provider_reference) {
        throw new Error("Transaction not yet initiated with provider");
      }

      // Increment verification attempts
      transaction.verification_attempts++;
      if (
        transaction.verification_attempts >
        transaction.max_verification_attempts
      ) {
        transaction.status = TRANSACTION_STATUS.EXPIRED;
        transaction.updated_at = new Date().toISOString();
        this.addToHistory(transactionId, "verification_expired", transaction);

        return {
          success: false,
          message: "Maximum verification attempts exceeded",
          data: transaction,
        };
      }

      // Verify with payment router
      const verificationResult = await this.paymentRouter.verifyTransaction(
        transaction.provider_reference,
        transaction.rail,
      );

      if (verificationResult.success) {
        // Update transaction status based on verification
        if (verificationResult.status === "success") {
          transaction.status = TRANSACTION_STATUS.SUCCESS;
          transaction.completed_at = new Date().toISOString();
          transaction.verification_attempts = 0; // Reset counter
        } else if (verificationResult.status === "failed") {
          transaction.status = TRANSACTION_STATUS.FAILED;
          transaction.failed_at = new Date().toISOString();
        }

        transaction.updated_at = new Date().toISOString();
        this.addToHistory(transactionId, "verification_completed", {
          status: verificationResult.status,
          amount: verificationResult.amount,
        });
      }

      return {
        success: verificationResult.success,
        data: transaction,
        verification: verificationResult,
      };
    } catch (error) {
      console.error("[TransactionService] Verify transaction error:", error);
      throw error;
    }
  }

  // ============================================
  // Transaction Management
  // ============================================

  /**
   * Cancel transaction
   * @param {String} transactionId - Transaction ID
   * @param {String} reason - Cancellation reason
   * @returns {Promise<Object>} Cancellation result
   */
  async cancelTransaction(transactionId, reason = "User cancelled") {
    try {
      const transaction = this.transactions.get(transactionId);
      if (!transaction) {
        throw new Error("Transaction not found");
      }

      if (transaction.status === TRANSACTION_STATUS.SUCCESS) {
        throw new Error("Cannot cancel completed transaction");
      }

      if (transaction.status === TRANSACTION_STATUS.CANCELLED) {
        throw new Error("Transaction already cancelled");
      }

      transaction.status = TRANSACTION_STATUS.CANCELLED;
      transaction.cancelled_at = new Date().toISOString();
      transaction.cancellation_reason = reason;
      transaction.updated_at = new Date().toISOString();

      this.addToHistory(transactionId, "cancelled", {
        reason,
        timestamp: transaction.cancelled_at,
      });

      return {
        success: true,
        message: "Transaction cancelled successfully",
        data: transaction,
      };
    } catch (error) {
      console.error("[TransactionService] Cancel transaction error:", error);
      throw error;
    }
  }

  /**
   * Refund transaction
   * @param {String} transactionId - Transaction ID
   * @param {Number} amount - Refund amount (optional, full refund if not provided)
   * @param {String} reason - Refund reason
   * @returns {Promise<Object>} Refund result
   */
  async refundTransaction(
    transactionId,
    amount = null,
    reason = "Refund requested",
  ) {
    try {
      const transaction = this.transactions.get(transactionId);
      if (!transaction) {
        throw new Error("Transaction not found");
      }

      if (transaction.status !== TRANSACTION_STATUS.SUCCESS) {
        throw new Error("Can only refund completed transactions");
      }

      if (transaction.status === TRANSACTION_STATUS.REFUNDED) {
        throw new Error("Transaction already refunded");
      }

      const refundAmount = amount || transaction.amount;

      // Process refund through payment router
      const refundResult = await this.paymentRouter.providers[
        transaction.rail
      ].refundTransaction(transaction.provider_reference, refundAmount);

      if (refundResult.success) {
        transaction.status = TRANSACTION_STATUS.REFUNDED;
        transaction.refunded_at = new Date().toISOString();
        transaction.refund_amount = refundAmount;
        transaction.refund_reason = reason;
        transaction.refund_reference = refundResult.data.refund_id;
        transaction.updated_at = new Date().toISOString();

        this.addToHistory(transactionId, "refunded", {
          amount: refundAmount,
          reason,
          refund_reference: refundResult.data.refund_id,
        });

        return {
          success: true,
          message: "Transaction refunded successfully",
          data: transaction,
        };
      } else {
        throw new Error(refundResult.message || "Refund failed");
      }
    } catch (error) {
      console.error("[TransactionService] Refund transaction error:", error);
      throw error;
    }
  }

  // ============================================
  // Transaction Queries
  // ============================================

  /**
   * Get transaction by ID
   * @param {String} transactionId - Transaction ID
   * @returns {Promise<Object>} Transaction details
   */
  async getTransaction(transactionId) {
    try {
      const transaction = this.transactions.get(transactionId);
      if (!transaction) {
        return {
          success: false,
          message: "Transaction not found",
        };
      }

      return {
        success: true,
        data: transaction,
      };
    } catch (error) {
      console.error("[TransactionService] Get transaction error:", error);
      throw error;
    }
  }

  /**
   * Get transaction by reference
   * @param {String} reference - Transaction reference
   * @returns {Promise<Object>} Transaction details
   */
  async getTransactionByReference(reference) {
    try {
      const transaction = Array.from(this.transactions.values()).find(
        (txn) => txn.reference === reference,
      );

      if (!transaction) {
        return {
          success: false,
          message: "Transaction not found",
        };
      }

      return {
        success: true,
        data: transaction,
      };
    } catch (error) {
      console.error(
        "[TransactionService] Get transaction by reference error:",
        error,
      );
      throw error;
    }
  }

  /**
   * Get user transactions
   * @param {String} userId - User ID
   * @param {Object} filters - Query filters
   * @returns {Promise<Object>} User transactions
   */
  async getUserTransactions(userId, filters = {}) {
    try {
      let transactions = Array.from(this.transactions.values()).filter(
        (txn) => txn.user_id === userId,
      );

      // Apply filters
      if (filters.status) {
        transactions = transactions.filter(
          (txn) => txn.status === filters.status,
        );
      }
      if (filters.type) {
        transactions = transactions.filter((txn) => txn.type === filters.type);
      }
      if (filters.rail) {
        transactions = transactions.filter((txn) => txn.rail === filters.rail);
      }
      if (filters.startDate && filters.endDate) {
        transactions = transactions.filter((txn) => {
          const date = new Date(txn.created_at);
          return (
            date >= new Date(filters.startDate) &&
            date <= new Date(filters.endDate)
          );
        });
      }

      // Sort by date (newest first)
      transactions.sort(
        (a, b) => new Date(b.created_at) - new Date(a.created_at),
      );

      // Pagination
      const page = parseInt(filters.page) || 1;
      const limit = parseInt(filters.limit) || 20;
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      const paginatedTransactions = transactions.slice(startIndex, endIndex);

      return {
        success: true,
        data: paginatedTransactions,
        pagination: {
          total: transactions.length,
          page,
          limit,
          totalPages: Math.ceil(transactions.length / limit),
        },
      };
    } catch (error) {
      console.error("[TransactionService] Get user transactions error:", error);
      throw error;
    }
  }

  /**
   * Get transaction history
   * @param {String} transactionId - Transaction ID
   * @returns {Promise<Object>} Transaction history
   */
  async getTransactionHistory(transactionId) {
    try {
      const history = this.transactionHistory.get(transactionId) || [];
      return {
        success: true,
        data: history,
      };
    } catch (error) {
      console.error(
        "[TransactionService] Get transaction history error:",
        error,
      );
      throw error;
    }
  }

  // ============================================
  // Transaction Statistics
  // ============================================

  /**
   * Get transaction statistics
   * @param {Object} filters - Query filters
   * @returns {Promise<Object>} Statistics
   */
  async getTransactionStatistics(filters = {}) {
    try {
      let transactions = Array.from(this.transactions.values());

      // Apply filters
      if (filters.startDate && filters.endDate) {
        transactions = transactions.filter((txn) => {
          const date = new Date(txn.created_at);
          return (
            date >= new Date(filters.startDate) &&
            date <= new Date(filters.endDate)
          );
        });
      }
      if (filters.userId) {
        transactions = transactions.filter(
          (txn) => txn.user_id === filters.userId,
        );
      }
      if (filters.rail) {
        transactions = transactions.filter((txn) => txn.rail === filters.rail);
      }

      const stats = {
        total: transactions.length,
        total_amount: transactions.reduce((sum, txn) => sum + txn.amount, 0),
        total_fees: transactions.reduce((sum, txn) => sum + txn.fee, 0),
        by_status: {},
        by_rail: {},
        by_type: {},
        success_rate: 0,
      };

      // Calculate by status
      transactions.forEach((txn) => {
        stats.by_status[txn.status] = (stats.by_status[txn.status] || 0) + 1;
        stats.by_rail[txn.rail] = (stats.by_rail[txn.rail] || 0) + 1;
        stats.by_type[txn.type] = (stats.by_type[txn.type] || 0) + 1;
      });

      // Calculate success rate
      const successful = stats.by_status[TRANSACTION_STATUS.SUCCESS] || 0;
      stats.success_rate =
        transactions.length > 0 ? (successful / transactions.length) * 100 : 0;

      return {
        success: true,
        data: stats,
      };
    } catch (error) {
      console.error("[TransactionService] Get statistics error:", error);
      throw error;
    }
  }

  // ============================================
  // Webhook Processing
  // ============================================

  /**
   * Process webhook from payment provider
   * @param {String} rail - Payment rail
   * @param {Object} payload - Webhook payload
   * @returns {Promise<Object>} Processing result
   */
  async processWebhook(rail, payload) {
    try {
      // Find transaction by reference
      const reference =
        payload.data?.reference || payload.data?.tx_ref || payload.data?.id;
      const transaction = Array.from(this.transactions.values()).find(
        (txn) =>
          txn.provider_reference === reference || txn.reference === reference,
      );

      if (!transaction) {
        console.warn(
          `[TransactionService] Webhook received for unknown transaction: ${reference}`,
        );
        return {
          success: false,
          message: "Transaction not found",
        };
      }

      // Update transaction status based on webhook
      const eventType = payload.event_type || payload.event;
      let newStatus = transaction.status;

      switch (eventType) {
        case "charge.success":
        case "transfer.success":
        case "payment.success":
          newStatus = TRANSACTION_STATUS.SUCCESS;
          transaction.completed_at = new Date().toISOString();
          break;
        case "charge.failed":
        case "transfer.failed":
        case "payment.failed":
          newStatus = TRANSACTION_STATUS.FAILED;
          transaction.failed_at = new Date().toISOString();
          transaction.error_message =
            payload.data?.gateway_response || "Payment failed";
          break;
        case "transfer.reversed":
          newStatus = TRANSACTION_STATUS.REFUNDED;
          break;
        default:
          console.log(
            `[TransactionService] Unhandled webhook event: ${eventType}`,
          );
      }

      transaction.status = newStatus;
      transaction.webhook_received = true;
      transaction.updated_at = new Date().toISOString();

      this.addToHistory(transactionId, "webhook_received", {
        event_type: eventType,
        rail,
        status: newStatus,
      });

      return {
        success: true,
        message: "Webhook processed successfully",
        data: transaction,
      };
    } catch (error) {
      console.error("[TransactionService] Process webhook error:", error);
      throw error;
    }
  }

  // ============================================
  // History Management
  // ============================================

  /**
   * Add entry to transaction history
   * @param {String} transactionId - Transaction ID
   * @param {String} action - Action performed
   * @param {Object} data - Action data
   */
  addToHistory(transactionId, action, data) {
    if (!this.transactionHistory.has(transactionId)) {
      this.transactionHistory.set(transactionId, []);
    }

    const historyEntry = {
      action,
      timestamp: new Date().toISOString(),
      data,
    };

    this.transactionHistory.get(transactionId).push(historyEntry);
  }

  // ============================================
  // Utility Methods
  // ============================================

  /**
   * Get all transactions (for admin)
   * @param {Object} filters - Query filters
   * @returns {Promise<Object>} All transactions
   */
  async getAllTransactions(filters = {}) {
    try {
      let transactions = Array.from(this.transactions.values());

      // Apply filters
      if (filters.status) {
        transactions = transactions.filter(
          (txn) => txn.status === filters.status,
        );
      }
      if (filters.rail) {
        transactions = transactions.filter((txn) => txn.rail === filters.rail);
      }
      if (filters.startDate && filters.endDate) {
        transactions = transactions.filter((txn) => {
          const date = new Date(txn.created_at);
          return (
            date >= new Date(filters.startDate) &&
            date <= new Date(filters.endDate)
          );
        });
      }

      // Sort by date (newest first)
      transactions.sort(
        (a, b) => new Date(b.created_at) - new Date(a.created_at),
      );

      // Pagination
      const page = parseInt(filters.page) || 1;
      const limit = parseInt(filters.limit) || 50;
      const startIndex = (page - 1) * limit;
      const endIndex = startIndex + limit;
      const paginatedTransactions = transactions.slice(startIndex, endIndex);

      return {
        success: true,
        data: paginatedTransactions,
        pagination: {
          total: transactions.length,
          page,
          limit,
          totalPages: Math.ceil(transactions.length / limit),
        },
      };
    } catch (error) {
      console.error("[TransactionService] Get all transactions error:", error);
      throw error;
    }
  }
}

// Export constants
module.exports = {
  TransactionService,
  TRANSACTION_STATUS,
  TRANSACTION_TYPES,
};
