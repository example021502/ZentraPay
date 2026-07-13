/**
 * Flutterwave Service - Secondary/Failover Payment Provider
 *
 * This service handles payment operations as a failover rail:
 * - Secondary payment processing when Paystack is unavailable
 * - Domestic payments in Ghana
 * - Bank transfers and mobile money
 *
 * @description Flutterwave serves as the backup payment rail for ZentraPay
 * @version 1.0.0
 * @author ZentraPay Team
 */

const axios = require("axios");
const crypto = require("crypto");
const dotenv = require("dotenv");

// Load environment variables
dotenv.config({ path: require("path").resolve(__dirname, "../.env") });

/**
 * FlutterwaveService Class
 * Encapsulates all Flutterwave API operations
 */
class FlutterwaveService {
  /**
   * Constructor - Initialize Flutterwave configuration
   */
  constructor() {
    this.secretKey = process.env.FLUTTERWAVE_TEST_SK;
    this.publicKey = process.env.FLUTTERWAVE_TEST_PK;
    this.baseURL =
      process.env.FLUTTERWAVE_BASE_URL || "https://api.flutterwave.com/v3";

    // Initialize axios instance
    this.client = axios.create({
      baseURL: this.baseURL,
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
        "Content-Type": "application/json",
      },
    });
  }

  /**
   * Initialize payment transaction
   * @param {Object} paymentData - Payment details
   * @returns {Promise<Object>} Payment initialization response
   */
  async initializePayment(paymentData) {
    try {
      // Validate required fields
      if (!paymentData.amount || !paymentData.email || !paymentData.reference) {
        throw new Error("Amount, email, and reference are required");
      }

      const payload = {
        amount: Math.round(paymentData.amount * 100), // Convert to cents
        currency: paymentData.currency || "GHS",
        email: paymentData.email,
        tx_ref: paymentData.reference,
        redirect_url: paymentData.callback_url,
        metadata: {
          user_id: paymentData.user_id,
          recipient_id: paymentData.recipient_id,
          recipient_name: paymentData.recipient_name,
          payment_type: "external_transfer",
          ...paymentData.metadata,
        },
      };

      const response = await this.client.post("/payments", payload);

      return {
        success: true,
        data: {
          authorization_url: response.data.data.link,
          access_code: response.data.data.access_code,
          reference: response.data.data.tx_ref,
          flutterwave_reference: response.data.data.id,
        },
      };
    } catch (error) {
      console.error(
        "Flutterwave Payment Initialization Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message || "Failed to initialize payment",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Verify payment transaction
   * @param {String} reference - Transaction reference
   * @returns {Promise<Object>} Verification response
   */
  async verifyPayment(reference) {
    try {
      if (!reference) {
        throw new Error("Transaction reference is required");
      }

      const response = await this.client.get(
        `/transactions/${reference}/verify`,
      );
      const transaction = response.data.data;

      return {
        success: true,
        status:
          transaction.status === "successful" ? "success" : transaction.status,
        amount: transaction.amount / 100, // Convert back from cents
        currency: transaction.currency,
        reference: transaction.tx_ref,
        flutterwave_reference: transaction.id,
        paid_at: transaction.created_at,
        channel: transaction.payment_type,
        customer: transaction.customer,
        metadata: transaction.meta,
      };
    } catch (error) {
      console.error(
        "Flutterwave Verification Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message: error.response?.data?.message || "Failed to verify payment",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Process bank transfer
   * @param {Object} transferData - Transfer details
   * @returns {Promise<Object>} Transfer response
   */
  async processTransfer(transferData) {
    try {
      if (
        !transferData.amount ||
        !transferData.account_number ||
        !transferData.bank_code
      ) {
        throw new Error("Amount, account number, and bank code are required");
      }

      const payload = {
        amount: Math.round(transferData.amount * 100),
        account_bank: transferData.bank_code,
        account_number: transferData.account_number,
        account_name: transferData.account_name,
        currency: transferData.currency || "GHS",
        reference: transferData.reference,
        narration: transferData.narration || "ZentraPay Transfer",
        callback_url: transferData.callback_url,
        meta: {
          user_id: transferData.user_id,
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
          fee: response.data.data.fee,
        },
      };
    } catch (error) {
      console.error(
        "Flutterwave Transfer Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message: error.response?.data?.message || "Failed to process transfer",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Get list of supported banks
   * @param {String} country - Country code (default: GH)
   * @returns {Promise<Object>} List of banks
   */
  async getBanks(country = "GH") {
    try {
      const response = await this.client.get(`/banks/${country}`);

      return {
        success: true,
        data: response.data.data,
      };
    } catch (error) {
      console.error(
        "Flutterwave Get Banks Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message: error.response?.data?.message || "Failed to fetch banks",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Get supported mobile money providers
   * @param {String} country - Country code (default: GH)
   * @returns {Promise<Object>} List of mobile money providers
   */
  async getMobileMoneyProviders(country = "GH") {
    try {
      const response = await this.client.get(`/mobile-money/${country}`);

      return {
        success: true,
        data: response.data.data,
      };
    } catch (error) {
      console.error(
        "Flutterwave Mobile Money Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message ||
          "Failed to fetch mobile money providers",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Initiate mobile money payment
   * @param {Object} paymentData - Payment details
   * @returns {Promise<Object>} Payment response
   */
  async initiateMobileMoneyPayment(paymentData) {
    try {
      const payload = {
        amount: Math.round(paymentData.amount * 100),
        currency: paymentData.currency || "GHS",
        email: paymentData.email,
        tx_ref: paymentData.reference,
        phone_number: paymentData.phone_number,
        network: paymentData.network, // MNO: MTN, VODAFONE, TIGO, etc.
        full_name: paymentData.full_name,
        redirect_url: paymentData.callback_url,
        meta: {
          user_id: paymentData.user_id,
          ...paymentData.metadata,
        },
      };

      const response = await this.client.post("/payments", payload);

      return {
        success: true,
        data: {
          authorization_url: response.data.data.link,
          reference: response.data.data.tx_ref,
          flutterwave_reference: response.data.data.id,
          status: response.data.data.status,
        },
      };
    } catch (error) {
      console.error(
        "Flutterwave Mobile Money Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message:
          error.response?.data?.message ||
          "Failed to initiate mobile money payment",
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
      const response = await this.client.get("/balances");

      return {
        success: true,
        data: response.data.data,
      };
    } catch (error) {
      console.error(
        "Flutterwave Balance Error:",
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
        "Flutterwave History Error:",
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
        .createHmac("sha256", this.secretKey)
        .update(payload)
        .digest("hex");

      return hash === signature;
    } catch (error) {
      console.error("Flutterwave Webhook Verification Error:", error);
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
      event_type: payload.event,
      event_data: payload.data,
      reference: payload.data?.tx_ref,
      status: payload.data?.status,
      amount: payload.data?.amount,
      currency: payload.data?.currency,
      timestamp: payload.created_at,
    };
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
        tx_ref: reference,
      };

      if (amount) {
        payload.amount = Math.round(amount * 100);
      }

      const response = await this.client.post("/refunds", payload);

      return {
        success: true,
        data: {
          refund_id: response.data.data.id,
          reference: response.data.data.tx_ref,
          amount: response.data.data.amount / 100,
          status: response.data.data.status,
        },
      };
    } catch (error) {
      console.error(
        "Flutterwave Refund Error:",
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
module.exports = FlutterwaveService;
