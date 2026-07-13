/**
 * Onafriq Service - Cross-Border Payment Provider
 *
 * This service handles all cross-border and international remittance operations:
 * - Cross-border money transfers across Africa
 * - Mobile money integrations
 * - International payout processing
 *
 * @description Onafriq provides extensive mobile money network across Africa
 * @version 1.0.0
 * @author ZentraPay Team
 */

const axios = require("axios");
const crypto = require("crypto");
const dotenv = require("dotenv");

// Load environment variables
dotenv.config({ path: require("path").resolve(__dirname, "../.env") });

/**
 * OnafriqService Class
 * Encapsulates all Onafriq API operations for cross-border payments
 */
class OnafriqService {
  /**
   * Constructor - Initialize Onafriq configuration
   */
  constructor() {
    this.apiKey = process.env.ONAFRIQ_API_KEY;
    this.apiSecret = process.env.ONAFRIQ_API_SECRET;
    this.baseURL = process.env.ONAFRIQ_BASE_URL || "https://api.onafriq.com/v1";
    this.senderId = process.env.ONAFRIQ_SENDER_ID;

    // Initialize axios instance
    this.client = axios.create({
      baseURL: this.baseURL,
      headers: {
        Authorization: `Bearer ${this.apiKey}`,
        "Content-Type": "application/json",
        "X-Sender-ID": this.senderId,
      },
    });
  }

  /**
   * Initiate cross-border transfer
   * @param {Object} transferData - Transfer details
   * @returns {Promise<Object>} Transfer response
   */
  async initiateTransfer(transferData) {
    try {
      // Validate required fields
      if (
        !transferData.amount ||
        !transferData.recipientPhone ||
        !transferData.recipientCountry
      ) {
        throw new Error("Amount, recipient phone, and country are required");
      }

      const payload = {
        amount: transferData.amount,
        currency: transferData.currency || "USD",
        recipient: {
          phone_number: transferData.recipientPhone,
          country: transferData.recipientCountry,
          name: transferData.recipientName,
          email: transferData.recipientEmail,
        },
        sender: {
          phone_number: transferData.senderPhone || "+233XXXXXXXXX",
          country: transferData.senderCountry || "GH",
          name: transferData.senderName,
        },
        reference: transferData.reference,
        narration: transferData.narration || "ZentraPay Cross-Border Transfer",
        callback_url: transferData.callback_url,
        metadata: {
          user_id: transferData.user_id,
          transaction_type: "crossborder_remittance",
          ...transferData.metadata,
        },
      };

      const response = await this.client.post("/transfers", payload);

      return {
        success: true,
        data: {
          transfer_id: response.data.data.id,
          reference: response.data.data.reference,
          status: response.data.data.status,
          amount: response.data.data.amount,
          currency: response.data.data.currency,
          recipient: response.data.data.recipient,
          estimated_delivery: response.data.data.estimated_delivery,
          fees: response.data.data.fees,
        },
      };
    } catch (error) {
      console.error(
        "Onafriq Transfer Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message: error.response?.data?.message || "Failed to initiate transfer",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Get transfer status
   * @param {String} reference - Transfer reference
   * @returns {Promise<Object>} Transfer status
   */
  async getTransferStatus(reference) {
    try {
      if (!reference) {
        throw new Error("Transfer reference is required");
      }

      const response = await this.client.get(`/transfers/${reference}`);

      return {
        success: true,
        data: {
          transfer_id: response.data.data.id,
          reference: response.data.data.reference,
          status: response.data.data.status,
          amount: response.data.data.amount,
          currency: response.data.data.currency,
          recipient: response.data.data.recipient,
          transaction_history: response.data.data.transaction_history,
          completed_at: response.data.data.completed_at,
        },
      };
    } catch (error) {
      console.error(
        "Onafriq Status Check Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message || "Failed to get transfer status",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Get supported countries and networks
   * @returns {Promise<Object>} Countries and networks
   */
  async getSupportedCountries() {
    try {
      const response = await this.client.get("/countries");

      return {
        success: true,
        data: response.data.data,
      };
    } catch (error) {
      console.error(
        "Onafriq Countries Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message ||
          "Failed to fetch supported countries",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Get transaction fees
   * @param {Object} feeData - Fee calculation details
   * @returns {Promise<Object>} Fee details
   */
  async calculateFees(feeData) {
    try {
      if (!feeData.amount || !feeData.recipientCountry) {
        throw new Error("Amount and recipient country are required");
      }

      const payload = {
        amount: feeData.amount,
        sender_country: feeData.senderCountry || "GH",
        recipient_country: feeData.recipientCountry,
        currency: feeData.currency || "USD",
      };

      const response = await this.client.post("/fees/calculate", payload);

      return {
        success: true,
        data: {
          fee: response.data.data.fee,
          total_amount: response.data.data.total_amount,
          currency: response.data.data.currency,
          breakdown: response.data.data.breakdown,
        },
      };
    } catch (error) {
      console.error(
        "Onafriq Fee Calculation Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message: error.response?.data?.message || "Failed to calculate fees",
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
      const response = await this.client.get("/account/balance");

      return {
        success: true,
        data: {
          balance: response.data.data.balance,
          currency: response.data.data.currency,
          available_balance: response.data.data.available_balance,
        },
      };
    } catch (error) {
      console.error(
        "Onafriq Balance Error:",
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
      const response = await this.client.get("/transactions", { params });

      return {
        success: true,
        data: response.data.data,
        pagination: response.data.meta,
      };
    } catch (error) {
      console.error(
        "Onafriq History Error:",
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
   * Verify webhook signature
   * @param {String} signature - Webhook signature
   * @param {String} payload - Raw request body
   * @returns {Boolean} Verification result
   */
  verifyWebhookSignature(signature, payload) {
    try {
      const hash = crypto
        .createHmac("sha256", this.apiSecret)
        .update(payload)
        .digest("hex");

      return hash === signature;
    } catch (error) {
      console.error("Onafriq Webhook Verification Error:", error);
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
      event_type: payload.event_type,
      transfer_id: payload.data?.id,
      reference: payload.data?.reference,
      status: payload.data?.status,
      amount: payload.data?.amount,
      currency: payload.data?.currency,
      timestamp: payload.timestamp,
    };
  }
}

// Export class for instantiation
module.exports = OnafriqService;
