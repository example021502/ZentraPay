/**
 * Remittance Service - Cross-Border Transfer Processing
 *
 * This service handles all remittance operations:
 * - POST /api/remittance/transfer - Cross-border remittance via OnAfriq
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
 * 2. Spring Boot Layer (Port 2000) - REMITTANCE PROCESSING
 *    - Validates request payload
 *    - Routes to OnAfriq gateway
 *    - Handles currency conversion
 *    - Records transaction atomically
 *
 * ============================================
 * REQUEST/RESPONSE FLOW
 * ============================================
 *
 * Frontend → Node.js → Spring Boot → OnAfriq
 *           (Auth)     (Process)      (External API)
 *
 * All responses follow this standardized format:
 * {
 *   "success": true/false,
 *   "result": { ... } | "data": { ... },
 *   "message": "Human readable message"
 * }
 */

const apiClient = require("../utils/apiClient");
const uuid = require("uuid");

class RemittanceService {
  /**
   * Initiate cross-border remittance transfer
   *
   * @param {Object} transferData - Transfer details
   * @param {String} transferData.user_id - User ID
   * @param {String} transferData.email - User email
   * @param {String} transferData.transactionReference - Unique reference
   * @param {Object} transferData.sourceTransaction - Source transaction details
   * @param {Object} transferData.recipientDetails - Recipient information
   * @param {String} transferData.payoutMethod - "bank" | "momo"
   * @param {Object} transferData.destinationDetails - Bank or mobile money details
   * @param {String} transferData.transactionPin - 4-digit PIN
   * @returns {Promise<Object>} Transfer response
   */
  async initiateTransfer(transferData) {
    try {
      const {
        user_id,
        email,
        transactionReference,
        sourceTransaction,
        recipientDetails,
        payoutMethod,
        destinationDetails,
        transactionPin,
      } = transferData;

      // Validate required fields
      if (
        !user_id ||
        !email ||
        !transactionReference ||
        !sourceTransaction ||
        !recipientDetails ||
        !payoutMethod ||
        !destinationDetails ||
        !transactionPin
      ) {
        return {
          success: false,
          message: "Validation Error: Missing required fields",
        };
      }

      // Build payload for Spring Boot OnAfriq gateway
      const payload = {
        user_id: user_id,
        email: email,
        transactionReference: transactionReference,
        sourceTransaction: sourceTransaction,
        recipientDetails: recipientDetails,
        payoutMethod: payoutMethod,
        destinationDetails: destinationDetails,
        transactionPin: transactionPin,
        gateway: "OnAfriq",
        isCrossBorder:
          sourceTransaction.sourceCurrencyCode !==
          sourceTransaction.destinationCurrencyCode,
      };

      console.log(
        "[RemittanceService] Initiating transfer: user=%s, ref=%s, amount=%s %s, method=%s",
        user_id,
        transactionReference,
        sourceTransaction.sourceAmount,
        sourceTransaction.sourceCurrencyCode,
        payoutMethod,
      );

      // Forward to Spring Boot backend
      const response = await apiClient.post(
        "/api/remittance/transfer",
        payload,
      );

      const result = response.data;

      console.log("[RemittanceService] Transfer response received:", result);

      if (result && result.success) {
        return {
          success: true,
          data: {
            transactionId: result.result?.transactionId || transactionReference,
            status: result.result?.status || "PENDING",
            sourceAmount: sourceTransaction.sourceAmount,
            sourceCurrency: sourceTransaction.sourceCurrencyCode,
            destinationAmount:
              result.result?.destinationAmount ||
              sourceTransaction.destinationAmount,
            destinationCurrency: sourceTransaction.destinationCurrencyCode,
            exchangeRate: result.result?.exchangeRate || 15.45,
            fee: result.result?.fee || 0.0,
            totalCharged:
              result.result?.totalCharged || sourceTransaction.sourceAmount,
            gatewayName: "OnAfriq",
            authorizationUrl: result.result?.authorizationUrl || null,
            accessCode: result.result?.accessCode || null,
            expiresAt: result.result?.expiresAt || null,
            createdAt: new Date().toISOString(),
          },
        };
      } else {
        return {
          success: false,
          message: result.message || "Transaction processing failed",
        };
      }
    } catch (error) {
      console.error("[RemittanceService] Transfer initiation error:", error);

      // Handle specific error types
      if (error.response) {
        return {
          success: false,
          message: error.response.data?.message || "Gateway processing error",
          error: error.response.data,
        };
      } else if (error.request) {
        return {
          success: false,
          message: "Payment gateway unavailable. Please try again later.",
          error: error.message,
        };
      } else {
        return {
          success: false,
          message: "Internal server error",
          error: error.message,
        };
      }
    }
  }

  /**
   * Get transfer status
   * @param {String} transactionId - Transaction ID
   * @returns {Promise<Object>} Transfer status
   */
  async getTransferStatus(transactionId) {
    try {
      if (!transactionId) {
        throw new Error("Transaction ID is required");
      }

      const response = await apiClient.get(
        `/api/remittance/transfer/${transactionId}`,
      );

      return {
        success: true,
        data: response.data,
      };
    } catch (error) {
      console.error("[RemittanceService] Get status error:", error);

      return {
        success: false,
        message:
          error.response?.data?.message || "Failed to get transfer status",
        error: error.response?.data || error.message,
      };
    }
  }
}

module.exports = RemittanceService;
