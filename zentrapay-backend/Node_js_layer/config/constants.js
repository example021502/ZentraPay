module.exports = {
  PLATFORM_VAULT_ID: "550e8400-e29b-41d4-a716-446655440000",
  TRANSACTION_STATUS: {
    PENDING: "pending",
    SUCCESS: "success",
    FAILED: "failed",
  },
  PAYMENT_GATEWAYS: {
    PAYSTACK: "paystack",
    FLUTTERWAVE: "flutterwave",
    ONAFRIQ: "onafriq",
    HUBTEL: "hubtel",
  },
  TRANSACTION_STATUS: {
    PENDING: "pending",
    SUCCESS: "success",
    FAILED: "failed",
    CANCELLED: "cancelled",
  },
  USER_ROLES: {
    USER: "user",
    ADMIN: "admin",
    SUPER_ADMIN: "super_admin",
  },
  HTTP_STATUS: {
    OK: 200,
    CREATED: 201,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    INTERNAL_SERVER_ERROR: 500,
  },
  RATE_LIMIT: {
    WINDOW_MS: 15 * 60 * 1000,
    MAX_REQUESTS: 100,
  },
};
