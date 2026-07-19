/**
 * Hubtel/AppsNmobile Service - Offline USSD Payment Provider
 *
 * This service handles offline and USSD-based payment operations:
 * - USSD payment initiation
 * - Offline transaction processing
 * - Mobile money collections via USSD
 *
 * @description Hubtel provides USSD services for users without internet connectivity
 * @version 1.0.0
 * @author ZentraPay Team
 */

const axios = require("axios");
const crypto = require("crypto");
const dotenv = require("dotenv");

// Load environment variables
dotenv.config({ path: require("path").resolve(__dirname, "../.env") });

/**
 * HubtelService Class
 * Encapsulates all Hubtel API operations for USSD/offline payments
 */
class HubtelService {
  /**
   * Constructor - Initialize Hubtel configuration
   */
  constructor() {
    this.clientId = process.env.HUBTEL_CLIENT_ID;
    this.clientSecret = process.env.HUBTEL_CLIENT_SECRET;
    this.apiKey = process.env.HUBTEL_API_KEY;
    this.baseURL = process.env.HUBTEL_BASE_URL || "https://api.hubtel.com/v1";
    this.ussdServiceCode = process.env.HUBTEL_USSD_SERVICE_CODE;

    // Initialize axios instance
    this.client = axios.create({
      baseURL: this.baseURL,
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        "Content-Type": "application/json",
      },
    });
  }

  /**
   * Initiate USSD payment
   * @param {Object} paymentData - Payment details
   * @returns {Promise<Object>} USSD payment response
   */
  async initiateUSSDPayment(paymentData) {
    try {
      // Validate required fields
      if (!paymentData.amount || !paymentData.customerPhone) {
        throw new Error("Amount and customer phone are required");
      }

      const payload = {
        amount: Math.round(paymentData.amount * 100), // Convert to pesewas
        currency: "GHS",
        customerPhone: paymentData.customerPhone,
        customerName: paymentData.customerName,
        description: paymentData.description || "ZentraPay USSD Payment",
        reference: paymentData.reference,
        callback_url: paymentData.callback_url,
        metadata: {
          user_id: paymentData.user_id,
          transaction_type: "ussd_payment",
          ...paymentData.metadata,
        },
      };

      const response = await this.client.post(
        "/merchantaccount/collections/initiate",
        payload,
      );

      return {
        success: true,
        data: {
          transaction_id: response.data.data.transactionId,
          ussd_code: response.data.data.ussdCode,
          reference: response.data.data.reference,
          status: response.data.data.status,
          expires_at: response.data.data.expiresAt,
        },
      };
    } catch (error) {
      console.error(
        "Hubtel USSD Payment Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message || "Failed to initiate USSD payment",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Check USSD transaction status
   * @param {String} reference - Transaction reference
   * @returns {Promise<Object>} Transaction status
   */
  async checkTransactionStatus(reference) {
    try {
      if (!reference) {
        throw new Error("Transaction reference is required");
      }

      const response = await this.client.get(
        `/merchantaccount/collections/${reference}`,
      );

      return {
        success: true,
        data: {
          transaction_id: response.data.data.transactionId,
          reference: response.data.data.reference,
          status: response.data.data.status,
          amount: response.data.data.amount / 100, // Convert from pesewas
          customer_phone: response.data.data.customerPhone,
          completed_at: response.data.data.completedAt,
        },
      };
    } catch (error) {
      console.error(
        "Hubtel Status Check Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message || "Failed to check transaction status",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Initiate mobile money collection
   * @param {Object} paymentData - Payment details
   * @returns {Promise<Object>} Mobile money response
   */
  async initiateMobileMoneyCollection(paymentData) {
    try {
      if (
        !paymentData.amount ||
        !paymentData.customerPhone ||
        !paymentData.network
      ) {
        throw new Error("Amount, customer phone, and network are required");
      }

      const payload = {
        amount: Math.round(paymentData.amount * 100),
        currency: "GHS",
        customerPhone: paymentData.customerPhone,
        customerName: paymentData.customerName,
        network: paymentData.network, // MTN, VODAFONE, TIGO, AIRTELTIGO
        description: paymentData.description || "ZentraPay Mobile Money",
        reference: paymentData.reference,
        callback_url: paymentData.callback_url,
        metadata: {
          user_id: paymentData.user_id,
          transaction_type: "mobile_money_collection",
          ...paymentData.metadata,
        },
      };

      const response = await this.client.post(
        "/merchantaccount/mobilemoney/collections/initiate",
        payload,
      );

      return {
        success: true,
        data: {
          transaction_id: response.data.data.transactionId,
          reference: response.data.data.reference,
          status: response.data.data.status,
          network: response.data.data.network,
        },
      };
    } catch (error) {
      console.error(
        "Hubtel Mobile Money Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message ||
          "Failed to initiate mobile money collection",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Get account balance
   * @returns {Promise<Object>} Account balance
   */
  async getAccountBalance() {
    try {
      const response = await this.client.get("/merchantaccount/balance");

      return {
        success: true,
        data: {
          balance: response.data.data.balance,
          currency: response.data.data.currency,
          available_balance: response.data.data.availableBalance,
        },
      };
    } catch (error) {
      console.error(
        "Hubtel Balance Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message || "Failed to get account balance",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Get transaction history
   * @param {Object} params - Query parameters
   * @returns {Promise<Object>} Transaction history
   */
  async getTransactionHistory(params = {}) {
    try {
      const response = await this.client.get("/merchantaccount/collections", {
        params: {
          limit: params.limit || 50,
          page: params.page || 1,
          startDate: params.startDate,
          endDate: params.endDate,
        },
      });

      return {
        success: true,
        data: response.data.data,
        pagination: response.data.meta,
      };
    } catch (error) {
      console.error(
        "Hubtel History Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message || "Failed to get transaction history",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Send USSD notification
   * @param {Object} notificationData - Notification details
   * @returns {Promise<Object>} Notification response
   */
  async sendUSSDNotification(notificationData) {
    try {
      if (!notificationData.phoneNumber || !notificationData.message) {
        throw new Error("Phone number and message are required");
      }

      const payload = {
        phoneNumber: notificationData.phoneNumber,
        message: notificationData.message,
        serviceCode: this.ussdServiceCode,
        metadata: {
          user_id: notificationData.user_id,
          ...notificationData.metadata,
        },
      };

      const response = await this.client.post("/messaging/send", payload);

      return {
        success: true,
        data: {
          message_id: response.data.data.messageId,
          status: response.data.data.status,
        },
      };
    } catch (error) {
      console.error(
        "Hubtel USSD Notification Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message || "Failed to send USSD notification",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Verify webhook signature
   * @param {String} signature - Webhook signature
   * @param {String} payload - Raw request body
   * @returns {Boolean} Verification result
   */
  verifyWebhookSignature(signature, payload) {
    try {
      const hash = crypto
        .createHmac("sha256", this.clientSecret)
        .update(payload)
        .digest("hex");

      return hash === signature;
    } catch (error) {
      console.error("Hubtel Webhook Verification Error:", error);
      return false;
    }
  }

  /**
   * Parse webhook event
   * @param {Object} payload - Webhook payload
   * @returns {Object} Parsed event data
   */
  parseWebhookEvent(payload) {
    return {
      event_type: payload.eventType,
      transaction_id: payload.data?.transactionId,
      reference: payload.data?.reference,
      status: payload.data?.status,
      amount: payload.data?.amount,
      customer_phone: payload.data?.customerPhone,
      timestamp: payload.timestamp,
    };
  }

  /**
   * Get supported mobile money networks
   * @returns {Promise<Object>} List of supported networks
   */
  async getSupportedNetworks() {
    try {
      const response = await this.client.get(
        "/merchantaccount/mobile-money/networks",
      );

      return {
        success: true,
        data: response.data.data,
      };
    } catch (error) {
      console.error(
        "Hubtel Networks Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message || "Failed to fetch supported networks",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Refund transaction
   * @param {String} reference - Transaction reference
   * @param {Number} amount - Amount to refund (optional, full refund if not provided)
   * @returns {Promise<Object>} Refund response
   */
  async refundTransaction(reference, amount = null) {
    try {
      const payload = {
        reference: reference,
      };

      if (amount) {
        payload.amount = Math.round(amount * 100);
      }

      const response = await this.client.post(
        "/merchantaccount/collections/refund",
        payload,
      );

      return {
        success: true,
        data: {
          refund_id: response.data.data.refundId,
          reference: response.data.data.reference,
          amount: response.data.data.amount / 100,
          status: response.data.data.status,
        },
      };
    } catch (error) {
      console.error(
        "Hubtel Refund Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message: error.response?.data?.message || "Failed to process refund",
        error: error.response?.data || error.message,
      };
    }
  }
}

// Export class for instantiation
module.exports = HubtelService;
