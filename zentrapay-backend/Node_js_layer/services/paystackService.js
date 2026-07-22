/**
 * Paystack Service - Handles all external payment operations
 *
 * This service manages:
 * - Payment initialization for external transfers
 * - Transaction verification
 * - Webhook handling for payment status updates
 * - Refund processing
 *
 * @description Uses Paystack API for processing external national transactions
 * @version 1.0.0
 * @author ZentraPay Team
 */

const axios = require("axios");
const dotenv = require("dotenv");

// Load environment variables
dotenv.config({ path: require("path").resolve(__dirname, "../.env") });

/**
 * PaystackService Class
 * Encapsulates all Paystack API operations
 */
class PaystackService {
  /**
   * Constructor - Initialize Paystack configuration
   * @description Sets up API keys and base URL from environment variables
   */
  constructor() {
    // Use test keys for development, production keys for live environment
    this.secretKey = process.env.PAYSTACK_TEST_SK;
    this.publicKey = process.env.PAYSTACK_TEST_PK;

    // Paystack API base URL
    this.baseURL = "https://api.paystack.co";

    // Initialize axios instance with default config
    this.client = axios.create({
      baseURL: this.baseURL,
      headers: {
        Authorization: `Bearer ${this.secretKey}`,
        "Content-Type": "application/json",
      },
    });
  }

  /**
   * Initialize a payment transaction
   * @description Creates a payment intent for external transfer
   * @param {Object} paymentData - Payment details
   * @param {number} paymentData.amount - Amount in kobo (multiply by 100 for GHS)
   * @param {string} paymentData.email - Customer email
   * @param {string} paymentData.currency - Currency code (GHS, USD, etc.)
   * @param {string} paymentData.reference - Unique transaction reference
   * @param {string} paymentData.callback_url - URL to redirect after payment
   * @param {Object} paymentData.metadata - Additional transaction data
   * @returns {Promise<Object>} Payment initialization response
   */
  async initializePayment(paymentData) {
    try {
      // Validate required fields
      if (!paymentData.amount || !paymentData.email || !paymentData.reference) {
        throw new Error("Amount, email, and reference are required");
      }

      // Convert amount to kobo (Paystack expects smallest currency unit)
      const amountInKobo = Math.round(paymentData.amount * 100);

      // Prepare request payload
      const payload = {
        amount: amountInKobo,
        email: paymentData.email,
        currency: paymentData.currency || "GHS",
        reference: paymentData.reference,
        callback_url:
          paymentData.callback_url ||
          `${process.env.BASE_URL}/api/payments/verify`,
        metadata: {
          // Store custom data for webhook verification
          user_id: paymentData.user_id,
          recipient_id: paymentData.recipient_id,
          recipient_name: paymentData.recipient_name,
          payment_type: "external_transfer",
          ...paymentData.metadata,
        },
      };

      // Make API call to Paystack
      const response = await this.client.post(
        "/transaction/initialize",
        payload,
      );

      // Return success response with payment details
      return {
        success: true,
        data: {
          authorization_url: response.data.data.authorization_url,
          access_code: response.data.data.access_code,
          reference: response.data.data.reference,
        },
      };
    } catch (error) {
      // Log error for debugging
      console.error(
        "Paystack Payment Initialization Error:",
        error.response?.data || error.message,
      );

      // Return formatted error
      return {
        success: false,
        message:
          error.response?.data?.message || "Failed to initialize payment",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Verify a payment transaction
   * @description Checks the status of a payment with Paystack
   * @param {string} reference - Transaction reference to verify
   * @returns {Promise<Object>} Transaction verification response
   */
  async verifyPayment(reference) {
    try {
      if (!reference) {
        throw new Error("Transaction reference is required");
      }

      // Make API call to verify transaction
      const response = await this.client.get(
        `/transaction/verify/${reference}`,
      );

      // Extract transaction data
      const transaction = response.data.data;

      // Return formatted response
      return {
        success: true,
        status: transaction.status, // 'success', 'failed', 'abandoned'
        amount: transaction.amount / 100, // Convert back from kobo
        currency: transaction.currency,
        reference: transaction.reference,
        paid_at: transaction.paid_at,
        channel: transaction.channel,
        customer: transaction.customer,
        metadata: transaction.metadata,
      };
    } catch (error) {
      console.error(
        "Paystack Verification Error:",
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
   * Process a transfer to external bank account
   * @description Initiates a transfer to a recipient's bank account
   * @param {Object} transferData - Transfer details
   * @param {number} transferData.amount - Amount to transfer (in GHS)
   * @param {string} transferData.recipient_code - Paystack recipient code
   * @param {string} transferData.reference - Unique transfer reference
   * @param {string} transferData.reason - Transfer description
   * @returns {Promise<Object>} Transfer response
   */
  async processTransfer(transferData) {
    try {
      // Validate required fields
      if (
        !transferData.amount ||
        !transferData.recipient_code ||
        !transferData.reference
      ) {
        throw new Error("Amount, recipient code, and reference are required");
      }

      // Convert amount to kobo
      const amountInKobo = Math.round(transferData.amount * 100);

      // Prepare transfer payload
      const payload = {
        amount: amountInKobo,
        recipient: transferData.recipient_code,
        reference: transferData.reference,
        reason: transferData.reason || "ZentraPay External Transfer",
      };

      // Make API call to initiate transfer
      const response = await this.client.post("/transfer", payload);

      return {
        success: true,
        data: {
          transfer_code: response.data.data.transfer_code,
          reference: response.data.data.reference,
          status: response.data.data.status,
        },
      };
    } catch (error) {
      console.error(
        "Paystack Transfer Error:",
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
   * Create a transfer recipient
   * @description Registers a new bank account for future transfers
   * @param {Object} recipientData - Recipient details
   * @param {string} recipientData.name - Recipient's full name
   * @param {string} recipientData.account_number - Bank account number
   * @param {string} recipientData.bank_code - Paystack bank code
   * @returns {Promise<Object>} Recipient creation response
   */
  async createRecipient(recipientData) {
    try {
      // Validate required fields
      if (
        !recipientData.name ||
        !recipientData.account_number ||
        !recipientData.bank_code
      ) {
        throw new Error("Name, account number, and bank code are required");
      }

      // Prepare recipient payload
      const payload = {
        type: "nuban", // Nigerian bank account type
        name: recipientData.name,
        account_number: recipientData.account_number,
        bank_code: recipientData.bank_code,
        currency: "GHS", // Ghanaian Cedi
      };

      // Make API call to create recipient
      const response = await this.client.post("/transferrecipient", payload);

      return {
        success: true,
        data: {
          recipient_code: response.data.data.recipient_code,
          name: response.data.data.name,
          account_number: response.data.data.details.account_number,
          bank_name: response.data.data.details.bank_name,
        },
      };
    } catch (error) {
      console.error(
        "Paystack Recipient Creation Error:",
        error.response?.data || error.message,
      );

      return {
        success: false,
        message: error.response?.data?.message || "Failed to create recipient",
        error: error.response?.data || error.message,
      };
    }
  }

  /**
   * Get list of supported banks
   * @description Fetches all banks supported by Paystack
   * @returns {Promise<Object>} List of banks
   */
  async getBanks() {
    try {
      // Make API call to get banks
      const response = await this.client.get("/bank?country=ghana");

      return {
        success: true,
        data: response.data.data,
      };
    } catch (error) {
      console.error(
        "Paystack Get Banks Error:",
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
   * Verify webhook signature
   * @description Validates that webhook is from Paystack
   * @param {string} signature - X-Paystack-Signature header
   * @param {string} payload - Raw request body
   * @returns {boolean} True if signature is valid
   */
  verifyWebhookSignature(signature, payload) {
    try {
      // Paystack signs webhooks using HMAC-SHA512
      const crypto = require("crypto");
      const hash = crypto
        .createHmac("sha512", this.secretKey)
        .update(payload)
        .digest("hex");

      // Compare signatures
      return hash === signature;
    } catch (error) {
      console.error("Webhook Signature Verification Error:", error);
      return false;
    }
  }
}

// Export class for instantiation
module.exports = PaystackService;
