/**
 * Payment Router Service - Multi-Rail Payment Architecture
 *
 * This service implements the multi-rail payment system for ZentraPay:
 * - Primary Rail: Paystack Ghana (domestic payments)
 * - Secondary Rail: Flutterwave Ghana (failover/backup)
 * - Cross-Border Rail: Onafriq (international remittances)
 * - Offline Rail: Hubtel/AppsNmobile (USSD/offline transactions)
 *
 * @description Routes payment requests to appropriate provider based on
 *              transaction type, availability, and business rules
 * @version 1.0.0
 * @author ZentraPay Team
 */

const axios = require("axios");
const crypto = require("crypto");
const PaystackService = require("./paystackService");
const FlutterwaveService = require("./flutterwaveService");
const OnafriqService = require("./onafriqService");
const HubtelService = require("./hubtelService");

// ============================================
// Circuit Breaker Implementation
// ============================================

class CircuitBreaker {
  constructor(options = {}) {
    this.threshold =
      options.threshold || parseInt(process.env.CIRCUIT_BREAKER_THRESHOLD) || 5;
    this.timeout =
      options.timeout || parseInt(process.env.CIRCUIT_BREAKER_TIMEOUT) || 30000;
    this.resetTimeout =
      options.resetTimeout ||
      parseInt(process.env.CIRCUIT_BREAKER_RESET_TIMEOUT) ||
      60000;

    this.failureCount = 0;
    this.lastFailureTime = null;
    this.state = "CLOSED"; // CLOSED, OPEN, HALF_OPEN
  }

  async execute(fn) {
    if (this.state === "OPEN") {
      if (Date.now() - this.lastFailureTime >= this.resetTimeout) {
        this.state = "HALF_OPEN";
        console.log(`[CircuitBreaker] Moving to HALF_OPEN state`);
      } else {
        throw new Error("Circuit breaker is OPEN - service unavailable");
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  onSuccess() {
    this.failureCount = 0;
    this.state = "CLOSED";
  }

  onFailure() {
    this.failureCount++;
    this.lastFailureTime = Date.now();

    if (this.failureCount >= this.threshold) {
      this.state = "OPEN";
      console.error(
        `[CircuitBreaker] Circuit OPEN after ${this.failureCount} failures. Will retry in ${this.resetTimeout}ms`,
      );
    }
  }

  getState() {
    return {
      state: this.state,
      failureCount: this.failureCount,
      lastFailureTime: this.lastFailureTime,
    };
  }
}

// ============================================
// Payment Rail Configuration
// ============================================

const RAIL_CONFIG = {
  paystack: {
    name: "Paystack Ghana",
    type: "primary",
    currency: ["GHS"],
    transactionTypes: [
      "domestic",
      "wallet_funding",
      "bank_payout",
      "mobile_money",
    ],
    baseURL: "https://api.paystack.co",
    environment: process.env.NODE_ENV === "production" ? "live" : "test",
  },
  flutterwave: {
    name: "Flutterwave Ghana",
    type: "secondary",
    currency: ["GHS", "USD"],
    transactionTypes: [
      "domestic",
      "wallet_funding",
      "bank_payout",
      "mobile_money",
    ],
    baseURL: "https://api.flutterwave.com/v3",
    environment: process.env.NODE_ENV === "production" ? "live" : "test",
  },
  onafriq: {
    name: "Onafriq",
    type: "crossborder",
    currency: ["GHS", "USD", "EUR", "GBP", "KES", "NGN"],
    transactionTypes: ["crossborder", "remittance", "international"],
    baseURL: process.env.ONAFRIQ_BASE_URL || "https://api.onafriq.com/v1",
    environment: process.env.NODE_ENV === "production" ? "live" : "sandbox",
  },
  hubtel: {
    name: "Hubtel/AppsNmobile",
    type: "offline",
    currency: ["GHS"],
    transactionTypes: ["ussd", "offline", "mobile_money"],
    baseURL: process.env.HUBTEL_BASE_URL || "https://api.hubtel.com/v1",
    environment: process.env.NODE_ENV === "production" ? "live" : "sandbox",
  },
};

// ============================================
// Payment Router Service
// ============================================

class PaymentRouter {
  constructor() {
    // Initialize service instances
    this.paystackService = new PaystackService();
    this.flutterwaveService = new FlutterwaveService();
    this.onafriqService = new OnafriqService();
    this.hubtelService = new HubtelService();

    this.circuitBreakers = {
      paystack: new CircuitBreaker(),
      flutterwave: new CircuitBreaker(),
      onafriq: new CircuitBreaker(),
      hubtel: new CircuitBreaker(),
    };

    this.healthStatus = {
      paystack: { healthy: true, lastCheck: Date.now() },
      flutterwave: { healthy: true, lastCheck: Date.now() },
      onafriq: { healthy: true, lastCheck: Date.now() },
      hubtel: { healthy: true, lastCheck: Date.now() },
    };

    // Initialize provider clients
    this.providers = {
      paystack: this.paystackService,
      flutterwave: this.flutterwaveService,
      onafriq: this.onafriqService,
      hubtel: this.hubtelService,
    };
  }

  // ============================================
  // Provider Initialization
  // ============================================

  initFlutterwaveProvider() {
    return {
      name: "Flutterwave",
      client: axios.create({
        baseURL: RAIL_CONFIG.flutterwave.baseURL,
        headers: {
          Authorization: `Bearer ${process.env.FLUTTERWAVE_TEST_SK}`,
          "Content-Type": "application/json",
        },
      }),
    };
  }

  initOnafriqProvider() {
    return {
      name: "Onafriq",
      client: axios.create({
        baseURL: RAIL_CONFIG.onafriq.baseURL,
        headers: {
          Authorization: `Bearer ${process.env.ONAFRIQ_API_KEY}`,
          "Content-Type": "application/json",
        },
      }),
    };
  }

  initHubtelProvider() {
    return {
      name: "Hubtel",
      client: axios.create({
        baseURL: RAIL_CONFIG.hubtel.baseURL,
        headers: {
          Authorization: `Bearer ${process.env.HUBTEL_API_KEY}`,
          "Content-Type": "application/json",
        },
      }),
    };
  }

  // ============================================
  // Rail Selection Logic
  // ============================================

  /**
   * Select appropriate payment rail based on transaction details
   * @param {Object} transaction - Transaction details
   * @returns {String} Selected rail identifier
   */
  selectRail(transaction) {
    const { type, currency, amount, recipientCountry, channel } = transaction;

    // 1. Offline/USSD transactions → Hubtel
    if (channel === "ussd" || channel === "offline") {
      return "hubtel";
    }

    // 2. Cross-border/International transactions → Onafriq
    if (
      type === "crossborder" ||
      type === "remittance" ||
      type === "international" ||
      recipientCountry !== "GH"
    ) {
      return "onafriq";
    }

    // 3. Domestic transactions → Primary rail (Paystack)
    if (
      type === "domestic" ||
      type === "wallet_funding" ||
      type === "bank_payout"
    ) {
      // Check if primary rail is healthy
      if (
        this.healthStatus.paystack.healthy &&
        this.circuitBreakers.paystack.state === "CLOSED"
      ) {
        return "paystack";
      }

      // Failover to secondary rail
      console.warn(
        "[PaymentRouter] Primary rail (Paystack) unavailable, failing over to Flutterwave",
      );
      if (
        this.healthStatus.flutterwave.healthy &&
        this.circuitBreakers.flutterwave.state === "CLOSED"
      ) {
        return "flutterwave";
      }
    }

    // 4. Default to primary rail
    return "paystack";
  }

  // ============================================
  // Payment Processing
  // ============================================

  /**
   * Process payment through selected rail
   * @param {Object} paymentData - Payment details
   * @returns {Promise<Object>} Payment response
   */
  async processPayment(paymentData) {
    const rail = this.selectRail(paymentData);
    const provider = this.providers[rail];
    const circuitBreaker = this.circuitBreakers[rail];

    console.log(`[PaymentRouter] Routing payment to ${rail} rail`);

    try {
      return await circuitBreaker.execute(async () => {
        return await this.routeToProvider(rail, provider, paymentData);
      });
    } catch (error) {
      console.error(
        `[PaymentRouter] Payment failed on ${rail}:`,
        error.message,
      );

      // Attempt failover if primary rail fails
      if (rail === "paystack") {
        console.log("[PaymentRouter] Attempting failover to Flutterwave");
        return await this.attemptFailover(paymentData, "flutterwave");
      }

      throw error;
    }
  }

  /**
   * Route payment to specific provider
   * @param {String} rail - Rail identifier
   * @param {Object} provider - Provider instance
   * @param {Object} paymentData - Payment details
   * @returns {Promise<Object>} Payment response
   */
  async routeToProvider(rail, provider, paymentData) {
    switch (rail) {
      case "paystack":
        return await this.paystackService.initializePayment(paymentData);

      case "flutterwave":
        return await this.processFlutterwavePayment(paymentData);

      case "onafriq":
        return await this.processOnafriqPayment(paymentData);

      case "hubtel":
        return await this.processHubtelPayment(paymentData);

      default:
        throw new Error(`Unsupported rail: ${rail}`);
    }
  }

  /**
   * Attempt failover to secondary rail
   * @param {Object} paymentData - Payment details
   * @param {String} failoverRail - Failover rail identifier
   * @returns {Promise<Object>} Payment response
   */
  async attemptFailover(paymentData, failoverRail) {
    const provider = this.providers[failoverRail];
    const circuitBreaker = this.circuitBreakers[failoverRail];

    try {
      return await circuitBreaker.execute(async () => {
        return await this.routeToProvider(failoverRail, provider, paymentData);
      });
    } catch (error) {
      console.error(
        `[PaymentRouter] Failover to ${failoverRail} also failed:`,
        error.message,
      );
      throw new Error("All payment rails unavailable");
    }
  }

  // ============================================
  // Provider-Specific Payment Processing
  // ============================================

  /**
   * Process payment via Flutterwave
   */
  async processFlutterwavePayment(paymentData) {
    try {
      const payload = {
        amount: Math.round(paymentData.amount * 100), // Convert to kobo/cents
        currency: paymentData.currency || "GHS",
        email: paymentData.email,
        tx_ref: paymentData.reference,
        redirect_url: paymentData.callback_url,
        metadata: {
          user_id: paymentData.user_id,
          ...paymentData.metadata,
        },
      };

      const response = await this.providers.flutterwave.client.post(
        "/payments",
        payload,
      );

      return {
        success: true,
        data: {
          authorization_url: response.data.data.link,
          reference: response.data.data.tx_ref,
          flutterwave_reference: response.data.data.id,
        },
      };
    } catch (error) {
      console.error(
        "Flutterwave Payment Error:",
        error.response?.data || error.message,
      );
      throw error;
    }
  }

  /**
   * Process cross-border payment via Onafriq
   */
  async processOnafriqPayment(paymentData) {
    try {
      const payload = {
        amount: paymentData.amount,
        currency: paymentData.currency,
        recipient: {
          phone_number: paymentData.recipientPhone,
          country: paymentData.recipientCountry,
          name: paymentData.recipientName,
        },
        sender: {
          phone_number: paymentData.senderPhone,
          country: "GH",
        },
        reference: paymentData.reference,
        narration: paymentData.narration || "ZentraPay Cross-Border Transfer",
      };

      const response = await this.providers.onafriq.client.post(
        "/transfers",
        payload,
      );

      return {
        success: true,
        data: {
          transfer_id: response.data.data.id,
          reference: response.data.data.reference,
          status: response.data.data.status,
        },
      };
    } catch (error) {
      console.error(
        "Onafriq Payment Error:",
        error.response?.data || error.message,
      );
      throw error;
    }
  }

  /**
   * Process USSD/offline payment via Hubtel
   */
  async processHubtelPayment(paymentData) {
    try {
      const payload = {
        amount: Math.round(paymentData.amount * 100),
        currency: "GHS",
        customerPhone: paymentData.customerPhone,
        description: paymentData.description || "ZentraPay USSD Payment",
        reference: paymentData.reference,
        callback_url: paymentData.callback_url,
      };

      const response = await this.providers.hubtel.client.post(
        "/merchantaccount/collections/initiate",
        payload,
      );

      return {
        success: true,
        data: {
          transaction_id: response.data.data.transactionId,
          ussd_code: response.data.data.ussdCode,
          reference: response.data.data.reference,
        },
      };
    } catch (error) {
      console.error(
        "Hubtel Payment Error:",
        error.response?.data || error.message,
      );
      throw error;
    }
  }

  // ============================================
  // Transaction Verification
  // ============================================

  /**
   * Verify transaction status
   * @param {String} reference - Transaction reference
   * @param {String} rail - Rail identifier (optional, auto-detects if not provided)
   * @returns {Promise<Object>} Verification result
   */
  async verifyTransaction(reference, rail = null) {
    if (!rail) {
      rail = this.detectRailFromReference(reference);
    }

    const provider = this.providers[rail];

    try {
      switch (rail) {
        case "paystack":
          return await this.paystackService.verifyPayment(reference);

        case "flutterwave":
          return await this.verifyFlutterwaveTransaction(reference);

        case "onafriq":
          return await this.verifyOnafriqTransaction(reference);

        case "hubtel":
          return await this.verifyHubtelTransaction(reference);

        default:
          throw new Error(`Unsupported rail: ${rail}`);
      }
    } catch (error) {
      console.error(
        `[PaymentRouter] Verification failed on ${rail}:`,
        error.message,
      );
      throw error;
    }
  }

  /**
   * Detect rail from transaction reference
   */
  detectRailFromReference(reference) {
    if (reference.startsWith("FLW")) return "flutterwave";
    if (reference.startsWith("ONA")) return "onafriq";
    if (reference.startsWith("HUB")) return "hubtel";
    return "paystack"; // Default to Paystack
  }

  async verifyFlutterwaveTransaction(reference) {
    try {
      const response = await this.providers.flutterwave.client.get(
        `/transactions/${reference}/verify`,
      );
      const transaction = response.data.data;

      return {
        success: true,
        status:
          transaction.status === "successful" ? "success" : transaction.status,
        amount: transaction.amount / 100,
        currency: transaction.currency,
        reference: transaction.tx_ref,
        paid_at: transaction.created_at,
        channel: transaction.payment_type,
      };
    } catch (error) {
      console.error(
        "Flutterwave Verification Error:",
        error.response?.data || error.message,
      );
      throw error;
    }
  }

  async verifyOnafriqTransaction(reference) {
    try {
      const response = await this.providers.onafriq.client.get(
        `/transfers/${reference}`,
      );
      const transfer = response.data.data;

      return {
        success: true,
        status: transfer.status,
        reference: transfer.reference,
        amount: transfer.amount,
        currency: transfer.currency,
      };
    } catch (error) {
      console.error(
        "Onafriq Verification Error:",
        error.response?.data || error.message,
      );
      throw error;
    }
  }

  async verifyHubtelTransaction(reference) {
    try {
      const response = await this.providers.hubtel.client.get(
        `/merchantaccount/collections/${reference}`,
      );
      const transaction = response.data.data;

      return {
        success: true,
        status: transaction.status,
        reference: transaction.reference,
        amount: transaction.amount / 100,
      };
    } catch (error) {
      console.error(
        "Hubtel Verification Error:",
        error.response?.data || error.message,
      );
      throw error;
    }
  }

  // ============================================
  // Health Monitoring
  // ============================================

  /**
   * Check health of all payment rails
   */
  async checkAllRailsHealth() {
    const healthChecks = {
      paystack: await this.checkRailHealth("paystack"),
      flutterwave: await this.checkRailHealth("flutterwave"),
      onafriq: await this.checkRailHealth("onafriq"),
      hubtel: await this.checkRailHealth("hubtel"),
    };

    this.healthStatus = healthChecks;
    return healthChecks;
  }

  /**
   * Check health of specific rail
   */
  async checkRailHealth(rail) {
    try {
      const provider = this.providers[rail];
      const startTime = Date.now();

      let response;
      switch (rail) {
        case "paystack":
          response = await provider.client.get("/balance");
          break;
        case "flutterwave":
          response = await provider.client.get(
            "/transactions?from=2024-01-01&to=2024-01-01&page=1",
          );
          break;
        case "onafriq":
          response = await provider.client.get("/health");
          break;
        case "hubtel":
          response = await provider.client.get("/merchantaccount/balance");
          break;
      }

      const responseTime = Date.now() - startTime;

      return {
        healthy: response.status === 200 || response.status === 401, // 401 is OK (just means auth required)
        lastCheck: Date.now(),
        responseTime,
        status: response.status,
      };
    } catch (error) {
      console.error(
        `[PaymentRouter] Health check failed for ${rail}:`,
        error.message,
      );
      return {
        healthy: false,
        lastCheck: Date.now(),
        error: error.message,
      };
    }
  }

  /**
   * Get health status of all rails
   */
  getHealthStatus() {
    return {
      rails: this.healthStatus,
      circuitBreakers: Object.entries(this.circuitBreakers).reduce(
        (acc, [rail, cb]) => {
          acc[rail] = cb.getState();
          return acc;
        },
        {},
      ),
    };
  }

  // ============================================
  // Webhook Handling
  // ============================================

  /**
   * Verify webhook signature
   * @param {String} rail - Rail identifier
   * @param {String} signature - Webhook signature
   * @param {String} payload - Raw payload
   * @returns {Boolean} Verification result
   */
  verifyWebhookSignature(rail, signature, payload) {
    switch (rail) {
      case "paystack":
        return this.paystackService.verifyWebhookSignature(signature, payload);

      case "flutterwave":
        return this.verifyFlutterwaveWebhook(signature, payload);

      case "onafriq":
        return this.verifyOnafriqWebhook(signature, payload);

      case "hubtel":
        return this.verifyHubtelWebhook(signature, payload);

      default:
        return false;
    }
  }

  verifyFlutterwaveWebhook(signature, payload) {
    const hash = crypto
      .createHmac("sha256", process.env.FLUTTERWAVE_TEST_SK)
      .update(payload)
      .digest("hex");
    return hash === signature;
  }

  verifyOnafriqWebhook(signature, payload) {
    const hash = crypto
      .createHmac("sha256", process.env.ONAFRIQ_API_SECRET)
      .update(payload)
      .digest("hex");
    return hash === signature;
  }

  verifyHubtelWebhook(signature, payload) {
    const hash = crypto
      .createHmac("sha256", process.env.HUBTEL_WEBHOOK_SECRET)
      .update(payload)
      .digest("hex");
    return hash === signature;
  }

  // ============================================
  // Utility Methods
  // ============================================

  /**
   * Get supported currencies for a rail
   */
  getSupportedCurrencies(rail) {
    return RAIL_CONFIG[rail]?.currency || [];
  }

  /**
   * Get supported transaction types for a rail
   */
  getSupportedTransactionTypes(rail) {
    return RAIL_CONFIG[rail]?.transactionTypes || [];
  }

  /**
   * Get rail configuration
   */
  getRailConfig(rail) {
    return RAIL_CONFIG[rail] || null;
  }

  /**
   * Get all rail configurations
   */
  getAllRailConfigs() {
    return RAIL_CONFIG;
  }
}

// Export singleton instance
module.exports = new PaymentRouter();
