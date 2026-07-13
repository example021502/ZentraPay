/**
 * Compliance Middleware - PCI DSS, AML/KYC, and Security
 *
 * This middleware implements:
 * - PCI DSS compliance checks
 * - AML/KYC validation
 * - Rate limiting
 * - Security headers
 * - Request validation
 *
 * @description Ensures regulatory compliance and security standards
 * @version 1.0.0
 * @author ZentraPay Team
 */

const rateLimit = require("express-rate-limit");
const helmet = require("helmet");
const crypto = require("crypto");
const dotenv = require("dotenv");

// Load environment variables
dotenv.config({ path: require("path").resolve(__dirname, "../.env") });

// ============================================
// Security Headers (Helmet)
// ============================================

/**
 * Apply security headers to all responses
 */
const securityHeaders = helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: [
        "'self'",
        "https://api.paystack.co",
        "https://api.flutterwave.com",
        "https://api.onafriq.com",
        "https://api.hubtel.com",
      ],
      fontSrc: ["'self'", "data:"],
      objectSrc: ["'none'"],
      mediaSrc: ["'self'"],
      frameSrc: ["'none'"],
    },
  },
  crossOriginEmbedderPolicy: true,
  crossOriginOpenerPolicy: true,
  crossOriginResourcePolicy: { policy: "same-origin" },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true,
  },
  ieNoOpen: true,
  noSniff: true,
  originAgentCluster: true,
  permittedCrossDomainPolicies: { permittedPolicies: "none" },
  referrerPolicy: { policy: "no-referrer" },
  xssFilter: true,
});

// ============================================
// Rate Limiting
// ============================================

/**
 * General API rate limiter
 * Limits: 100 requests per 15 minutes per IP
 */
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per windowMs
  message: {
    success: false,
    message: "Too many requests, please try again later",
    retryAfter: "15 minutes",
  },
  standardHeaders: true,
  legacyHeaders: false,
  // Skip rate limiting for webhooks
  skip: (req) => req.path.startsWith("/api/webhooks"),
});

/**
 * Payment API rate limiter (stricter)
 * Limits: 10 requests per minute per IP
 */
const paymentLimiter = rateLimit({
  windowMs: 1 * 60 * 1000, // 1 minute
  max: 10, // Limit each IP to 10 payment requests per minute
  message: {
    success: false,
    message: "Too many payment requests, please try again later",
    retryAfter: "1 minute",
  },
  standardHeaders: true,
  legacyHeaders: false,
});

/**
 * Authentication rate limiter
 * Limits: 5 requests per 5 minutes per IP
 */
const authLimiter = rateLimit({
  windowMs: 5 * 60 * 1000, // 5 minutes
  max: 5, // Limit each IP to 5 auth requests per 5 minutes
  message: {
    success: false,
    message: "Too many authentication attempts, please try again later",
    retryAfter: "5 minutes",
  },
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true, // Don't count successful requests
});

// ============================================
// PCI DSS Compliance
// ============================================

/**
 * PCI DSS Compliance Checker
 * Ensures sensitive data is handled according to PCI DSS standards
 */
class PCICompliance {
  /**
   * Validate that no sensitive card data is logged
   */
  static sanitizeLogData(data) {
    const sensitiveFields = [
      "card_number",
      "cvv",
      "cvc",
      "pin",
      "expiry_month",
      "expiry_year",
      "exp_month",
      "exp_year",
      "security_code",
      "password",
      "pincode",
    ];

    const sanitized = { ...data };

    sensitiveFields.forEach((field) => {
      if (sanitized[field]) {
        sanitized[field] = "***REDACTED***";
      }
    });

    return sanitized;
  }

  /**
   * Validate request doesn't contain sensitive card data
   */
  static validateNoSensitiveData(req, res, next) {
    const body = req.body;
    const sensitiveFields = [
      "card_number",
      "cvv",
      "cvc",
      "pin",
      "expiry_month",
      "expiry_year",
      "exp_month",
      "exp_year",
      "security_code",
    ];

    const foundSensitive = sensitiveFields.filter((field) => body[field]);

    if (foundSensitive.length > 0) {
      console.error(
        "[PCI] Sensitive data detected in request:",
        foundSensitive,
      );
      return res.status(400).json({
        success: false,
        message: "Sensitive card data should not be sent to the API",
      });
    }

    next();
  }

  /**
   * Ensure TLS/HTTPS is used (except in development)
   */
  static enforceHTTPS(req, res, next) {
    if (process.env.NODE_ENV === "production" && !req.secure) {
      return res.status(403).json({
        success: false,
        message: "HTTPS is required in production",
      });
    }
    next();
  }
}

// ============================================
// AML/KYC Compliance
// ============================================

/**
 * AML/KYC Compliance Checker
 * Implements anti-money laundering and know-your-customer checks
 */
class AMLCompliance {
  /**
   * Transaction monitoring thresholds
   */
  static THRESHOLDS = {
    SINGLE_TRANSACTION_LIMIT: 50000, // GHS 50,000
    DAILY_LIMIT: 100000, // GHS 100,000
    MONTHLY_LIMIT: 500000, // GHS 500,000
    SUSPICIOUS_AMOUNT: 100000, // GHS 100,000 - requires additional verification
  };

  /**
   * Validate transaction amount against AML thresholds
   */
  static validateTransactionAmount(amount, userId, userTransactions = []) {
    const violations = [];

    // Check single transaction limit
    if (amount > this.THRESHOLDS.SINGLE_TRANSACTION_LIMIT) {
      violations.push(
        `Transaction amount exceeds single transaction limit of GHS ${this.THRESHOLDS.SINGLE_TRANSACTION_LIMIT}`,
      );
    }

    // Check daily limit
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const dailyTotal = userTransactions
      .filter((txn) => new Date(txn.created_at) >= today)
      .reduce((sum, txn) => sum + txn.amount, 0);

    if (dailyTotal + amount > this.THRESHOLDS.DAILY_LIMIT) {
      violations.push(
        `Transaction would exceed daily limit of GHS ${this.THRESHOLDS.DAILY_LIMIT}`,
      );
    }

    // Check monthly limit
    const monthStart = new Date(today.getFullYear(), today.getMonth(), 1);
    const monthlyTotal = userTransactions
      .filter((txn) => new Date(txn.created_at) >= monthStart)
      .reduce((sum, txn) => sum + txn.amount, 0);

    if (monthlyTotal + amount > this.THRESHOLDS.MONTHLY_LIMIT) {
      violations.push(
        `Transaction would exceed monthly limit of GHS ${this.THRESHOLDS.MONTHLY_LIMIT}`,
      );
    }

    // Flag suspicious amounts
    if (amount > this.THRESHOLDS.SUSPICIOUS_AMOUNT) {
      violations.push("Transaction amount requires additional verification");
    }

    return {
      valid: violations.length === 0,
      violations,
      requiresEnhancedDueDiligence: amount > this.THRESHOLDS.SUSPICIOUS_AMOUNT,
    };
  }

  /**
   * Validate user KYC status
   */
  static validateKYCStatus(user) {
    // In production, check against database
    // For now, return basic validation
    if (!user) {
      return {
        valid: false,
        message: "User not found",
      };
    }

    // Check if user has completed KYC
    if (!user.kyc_verified) {
      return {
        valid: false,
        message: "KYC verification required",
        action: "complete_kyc",
      };
    }

    return {
      valid: true,
      message: "KYC verified",
    };
  }

  /**
   * Generate transaction reference for audit trail
   */
  static generateAuditReference() {
    const timestamp = Date.now().toString(36);
    const random = crypto.randomBytes(8).toString("hex");
    return `AML-${timestamp}-${random}`.toUpperCase();
  }
}

// ============================================
// Request Validation
// ============================================

/**
 * Validate request payload structure
 */
const validateRequest = (schema) => {
  return (req, res, next) => {
    const errors = [];

    // Validate required fields
    if (schema.required) {
      schema.required.forEach((field) => {
        if (!req.body[field]) {
          errors.push(`${field} is required`);
        }
      });
    }

    // Validate field types
    if (schema.types) {
      Object.entries(schema.types).forEach(([field, type]) => {
        if (req.body[field] !== undefined && typeof req.body[field] !== type) {
          errors.push(`${field} must be of type ${type}`);
        }
      });
    }

    // Validate numeric ranges
    if (schema.ranges) {
      Object.entries(schema.ranges).forEach(([field, range]) => {
        if (req.body[field] !== undefined) {
          const value = parseFloat(req.body[field]);
          if (isNaN(value)) {
            errors.push(`${field} must be a number`);
          } else if (range.min && value < range.min) {
            errors.push(`${field} must be at least ${range.min}`);
          } else if (range.max && value > range.max) {
            errors.push(`${field} must not exceed ${range.max}`);
          }
        }
      });
    }

    if (errors.length > 0) {
      return res.status(400).json({
        success: false,
        message: "Validation failed",
        errors,
      });
    }

    next();
  };
};

// ============================================
// IP Whitelisting (Optional)
// ============================================

/**
 * IP Whitelist middleware
 * Restricts access to specific IP addresses
 */
const ipWhitelist = (allowedIPs) => {
  return (req, res, next) => {
    const clientIP = req.ip || req.connection.remoteAddress;

    if (!allowedIPs.includes(clientIP)) {
      console.warn(
        `[Security] Blocked request from non-whitelisted IP: ${clientIP}`,
      );
      return res.status(403).json({
        success: false,
        message: "Access denied from this IP address",
      });
    }

    next();
  };
};

// ============================================
// CORS Configuration
// ============================================

/**
 * CORS configuration for production
 */
const corsOptions = {
  origin:
    process.env.NODE_ENV === "production"
      ? ["https://zentrapay.com", "https://app.zentrapay.com"]
      : "*", // Allow all in development
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
  allowedHeaders: ["Content-Type", "Authorization", "X-Requested-With"],
  exposedHeaders: ["Authorization"],
  credentials: true,
  maxAge: 86400, // 24 hours
};

// ============================================
// Export Middleware
// ============================================

module.exports = {
  // Security
  securityHeaders,
  corsOptions,

  // Rate Limiters
  generalLimiter,
  paymentLimiter,
  authLimiter,

  // Compliance
  PCICompliance,
  AMLCompliance,

  // Validation
  validateRequest,

  // IP Control
  ipWhitelist,

  // Common schemas
  schemas: {
    payment: {
      required: ["type", "amount", "recipient"],
      types: {
        type: "string",
        amount: "number",
        recipient: "object",
      },
      ranges: {
        amount: { min: 1, max: 1000000 },
      },
    },
    transaction: {
      required: ["reference"],
      types: {
        reference: "string",
      },
    },
  },
};
