/**
 * Webhook Routes - Payment Provider Webhook Handlers
 *
 * This module handles webhook callbacks from all payment providers:
 * - Paystack webhooks
 * - Flutterwave webhooks
 * - Onafriq webhooks
 * - Hubtel webhooks
 *
 * @description Centralized webhook handling for all payment rails
 * @version 1.0.0
 * @author ZentraPay Team
 */

const express = require("express");
const router = express.Router();
const TransactionService = require("../services/transactionService");
const PaymentRouter = require("../services/paymentRouter");
const crypto = require("crypto");

// ============================================
// Webhook Utilities
// ============================================

/**
 * Verify webhook signature
 * @param {String} rail - Payment rail
 * @param {String} signature - Signature from header
 * @param {String} payload - Raw request body
 * @returns {Boolean} Verification result
 */
const verifyWebhook = (rail, signature, payload) => {
  if (!signature || !payload) {
    return false;
  }
  return PaymentRouter.verifyWebhookSignature(rail, signature, payload);
};

/**
 * Send webhook response immediately to prevent timeout
 */
const sendImmediateResponse = (res, status = 200) => {
  res.status(status).json({ received: true });
};

// ============================================
// Paystack Webhooks
// ============================================

/**
 * @route   POST /api/webhooks/paystack
 * @desc    Handle Paystack webhook events
 * @access  Public (verified by signature)
 */
router.post(
  "/paystack",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    try {
      const signature = req.headers["x-paystack-signature"];
      const payload = req.body;

      // Verify webhook signature
      if (!verifyWebhook("paystack", signature, payload)) {
        console.error("[Webhook] Invalid Paystack webhook signature");
        return res.status(401).json({ error: "Invalid signature" });
      }

      console.log(`[Webhook] Received Paystack webhook: ${payload.event}`);

      // Process webhook asynchronously
      setImmediate(async () => {
        try {
          await TransactionService.processWebhook("paystack", payload);
        } catch (error) {
          console.error("[Webhook] Error processing Paystack webhook:", error);
        }
      });

      // Send immediate response to Paystack
      sendImmediateResponse(res, 200);
    } catch (error) {
      console.error("[Webhook] Paystack webhook error:", error);
      sendImmediateResponse(res, 500);
    }
  },
);

// ============================================
// Flutterwave Webhooks
// ============================================

/**
 * @route   POST /api/webhooks/flutterwave
 * @desc    Handle Flutterwave webhook events
 * @access  Public (verified by signature)
 */
router.post(
  "/flutterwave",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    try {
      const signature = req.headers["verif-hash"];
      const payload = req.body;

      // Verify webhook signature
      if (!verifyWebhook("flutterwave", signature, payload)) {
        console.error("[Webhook] Invalid Flutterwave webhook signature");
        return res.status(401).json({ error: "Invalid signature" });
      }

      console.log(`[Webhook] Received Flutterwave webhook: ${payload.event}`);

      // Process webhook asynchronously
      setImmediate(async () => {
        try {
          await TransactionService.processWebhook("flutterwave", payload);
        } catch (error) {
          console.error(
            "[Webhook] Error processing Flutterwave webhook:",
            error,
          );
        }
      });

      // Send immediate response to Flutterwave
      sendImmediateResponse(res, 200);
    } catch (error) {
      console.error("[Webhook] Flutterwave webhook error:", error);
      sendImmediateResponse(res, 500);
    }
  },
);

// ============================================
// Onafriq Webhooks
// ============================================

/**
 * @route   POST /api/webhooks/onafriq
 * @desc    Handle Onafriq webhook events
 * @access  Public (verified by signature)
 */
router.post(
  "/onafriq",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    try {
      const signature = req.headers["x-onafriq-signature"];
      const payload = req.body;

      // Verify webhook signature
      if (!verifyWebhook("onafriq", signature, payload)) {
        console.error("[Webhook] Invalid Onafriq webhook signature");
        return res.status(401).json({ error: "Invalid signature" });
      }

      console.log(`[Webhook] Received Onafriq webhook: ${payload.event_type}`);

      // Process webhook asynchronously
      setImmediate(async () => {
        try {
          await TransactionService.processWebhook("onafriq", payload);
        } catch (error) {
          console.error("[Webhook] Error processing Onafriq webhook:", error);
        }
      });

      // Send immediate response to Onafriq
      sendImmediateResponse(res, 200);
    } catch (error) {
      console.error("[Webhook] Onafriq webhook error:", error);
      sendImmediateResponse(res, 500);
    }
  },
);

// ============================================
// Hubtel Webhooks
// ============================================

/**
 * @route   POST /api/webhooks/hubtel
 * @desc    Handle Hubtel webhook events
 * @access  Public (verified by signature)
 */
router.post(
  "/hubtel",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    try {
      const signature = req.headers["x-hubtel-signature"];
      const payload = req.body;

      // Verify webhook signature
      if (!verifyWebhook("hubtel", signature, payload)) {
        console.error("[Webhook] Invalid Hubtel webhook signature");
        return res.status(401).json({ error: "Invalid signature" });
      }

      console.log(`[Webhook] Received Hubtel webhook: ${payload.eventType}`);

      // Process webhook asynchronously
      setImmediate(async () => {
        try {
          await TransactionService.processWebhook("hubtel", payload);
        } catch (error) {
          console.error("[Webhook] Error processing Hubtel webhook:", error);
        }
      });

      // Send immediate response to Hubtel
      sendImmediateResponse(res, 200);
    } catch (error) {
      console.error("[Webhook] Hubtel webhook error:", error);
      sendImmediateResponse(res, 500);
    }
  },
);

// ============================================
// Generic Webhook Handler (Fallback)
// ============================================

/**
 * @route   POST /api/webhooks/:rail
 * @desc    Generic webhook handler for any rail
 * @access  Public (verified by signature)
 */
router.post(
  "/:rail",
  express.raw({ type: "application/json" }),
  async (req, res) => {
    try {
      const { rail } = req.params;
      const signature =
        req.headers["x-signature"] || req.headers["x-webhook-signature"];
      const payload = req.body;

      // Verify webhook signature
      if (!verifyWebhook(rail, signature, payload)) {
        console.error(`[Webhook] Invalid ${rail} webhook signature`);
        return res.status(401).json({ error: "Invalid signature" });
      }

      console.log(`[Webhook] Received ${rail} webhook`);

      // Process webhook asynchronously
      setImmediate(async () => {
        try {
          await TransactionService.processWebhook(rail, payload);
        } catch (error) {
          console.error(`[Webhook] Error processing ${rail} webhook:`, error);
        }
      });

      // Send immediate response
      sendImmediateResponse(res, 200);
    } catch (error) {
      console.error("[Webhook] Generic webhook error:", error);
      sendImmediateResponse(res, 500);
    }
  },
);

// ============================================
// Webhook Testing (Development Only)
// ============================================

/**
 * @route   POST /api/webhooks/test/:rail
 * @desc    Test webhook endpoint (DEVELOPMENT ONLY)
 * @access  Public
 */
if (process.env.NODE_ENV !== "production") {
  router.post("/test/:rail", async (req, res) => {
    try {
      const { rail } = req.params;
      const payload = req.body;

      console.log(`[Webhook] Test webhook for ${rail}:`, payload);

      // Process webhook
      const result = await TransactionService.processWebhook(rail, payload);

      return res.status(200).json({
        success: true,
        message: "Test webhook processed",
        data: result.data,
      });
    } catch (error) {
      console.error("[Webhook] Test webhook error:", error);
      return res.status(500).json({
        success: false,
        message: "Failed to process test webhook",
        error: error.message,
      });
    }
  });
}

module.exports = router;
