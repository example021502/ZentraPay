// wallets, currency accounts, linked banks, balances
const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");

{
  /*
  ===============================================
  ACCOUNTS ALL BALANCES ROUTE
  ===============================================
  */
}
router.get("/balances/all", authenticateToken, async (req, res) => {
  const userId = req.userId;
  try {
    const response = await apiClient.get(`/api/currencyBalances/all/${userId}`);
    console.log("ALL BALANCES:: ", response.data);
    if (response.data && response.data.success) {
      return res.json({
        success: true,
        message: response.data.message || "Balances fetched successfully",
        data: response.data.data,
      });
    } else {
      return res.json({
        success: false,
        message: response.data.message || "Failed to fetch balances",
      });
    }
  } catch (e) {
    console.log("ERROR:: ", e);
    return res.json({
      success: false,
      message: e.response?.data?.message ?? e.message ?? "Network Error",
    });
  }
});
{
  /*
  ===============================================
  ACCOUNTS FIAT BALANCES ROUTE
  ===============================================
  */
}
router.get("/balances/fiatBalances", authenticateToken, async (req, res) => {
  const userId = req.userId;
  try {
    const response = await apiClient.get(
      `/api/currencyBalances/fiatBalances/${userId}`,
    );
    console.log("FIAT BALANCES:: ", response.data);
    if (response.data && response.data.success) {
      return res.json({
        success: true,
        message: response.data.message || "Fiat balances fetched successfully",
        data: response.data.data,
      });
    } else {
      return res.json({
        success: false,
        message: response.data.message || "Failed to fetch fiat balances",
      });
    }
  } catch (e) {
    console.log("ERROR:: ", e);
    return res.json({
      success: false,
      message: e.response?.data?.message ?? e.message ?? "Network Error",
    });
  }
});
{
  /*
  ===============================================
  ACCOUNTS CRYPTO BALANCES ROUTE
  ===============================================
  */
}
router.get("/balances/cryptoBalances", authenticateToken, async (req, res) => {
  const userId = req.userId;
  if (!userId) {
    return res.json({ success: false, message: "User error, try again." });
  }
  try {
    const response = await apiClient.get(
      `/api/currencyBalances/cryptoBalances/${userId}`,
    );
    console.log("CRYPTO BALANCES:: ", response.data);
    if (response.data && response.data.success) {
      return res.json({
        success: true,
        message:
          response.data.message || "Crypto balances fetched successfully",
        data: response.data.data,
      });
    } else {
      return res.json({
        success: false,
        message: response.data.message || "Failed to fetch crypto balances",
      });
    }
  } catch (e) {
    console.log("ERROR:: ", e);
    return res.json({
      success: false,
      message: e.response?.data?.message ?? e.message ?? "Network Error",
    });
  }
});

// CREATE FIAT ACCOUNT
router.post("/newAccount/fiat", authenticateToken, async (req, res) => {
  const userId = req.userId;
  if (!userId) {
    return res.json({ success: false, message: "User error, try again." });
  }
  try {
    const requestData = {
      ...req.body,
      userId: userId,
    };
    const response = await apiClient.post(
      "/api/accounts/newAccount/fiat",
      requestData,
    );
    console.log("CREATE FIAT ACCOUNT:: ", response.data);
    if (response.data && response.data.success) {
      return res.json({
        success: true,
        message: response.data.message || "Fiat account created successfully",
        data: response.data.data,
      });
    } else {
      return res.json({
        success: response.data.success || false,
        message: response.data.message || "Failed to create fiat account",
      });
    }
  } catch (e) {
    console.log("ERROR:: ", e);
    return res.json({
      success: false,
      message: e.response?.data?.message ?? e.message ?? "Network Error",
    });
  }
});

// CREATE CRYPTO ACCOUNT
router.post("/newAccount/crypto", authenticateToken, async (req, res) => {
  const userId = req.userId;
  try {
    const requestData = {
      ...req.body,
      userId: userId,
    };
    const response = await apiClient.post(
      "/api/accounts/newAccount/crypto",
      requestData,
    );
    console.log("CREATE CRYPTO ACCOUNT:: ", response.data);
    if (response.data && response.data.success) {
      return res.json({
        success: true,
        message: response.data.message || "Crypto account created successfully",
        data: response.data.data,
      });
    } else {
      return res.json({
        success: false,
        message: response.data.message || "Failed to create crypto account",
      });
    }
  } catch (e) {
    console.log("ERROR:: ", e);
    return res.json({
      success: false,
      message: e.response?.data?.message ?? e.message ?? "Network Error",
    });
  }
});

// GETTING ALL THE SUPPORTED CURRENCIES FOR CREATING NEW FIAT CURRENCY ACCOUNTS
router.get(
  "/supportedCurrencyAccounts",
  authenticateToken,
  async (req, res) => {
    try {
      const response = await apiClient.get("/api/supportedCurrencyAccounts");
      // console.log(response);
      console.log("THE ACCOUNTS ARE:: ", response.data);
      const data = response.data;
      if (data && data.success) {
        return res.json({
          success: true,
          message: data.message || "Currencies fetched successfully",
          accounts: data.data.accounts,
        });
      } else {
        return res.json({
          success: false,
          message: response.data.message || "Fetch Failed",
        });
      }
    } catch (e) {
      // console.log("ERROR:: ", e);

      // paystack === 
      // onafriq === 
      // flutterwave === 3fb048bb-e5bf-4932-a5cc-b6a325392dd1

      // Handle connection refused (Spring Boot is down or unreachable)
      if (e.code === "ECONNREFUSED") {
        return res.status(503).json({
          success: false,
          message: "Server error. Please try again later.",
        });
      }

      // Handle specific HTTP status codes returned by Spring Boot
      if (e.response) {
        const status = e.response.status;

        if (status === 403 || status === 401) {
          return res.status(401).json({
            success: false,
            message: "Authentication failed. Please log in again.",
          });
        }

        if (status === 404) {
          return res.status(404).json({
            success: false,
            message: "The requested resource could not be found.",
          });
        }
      }

      // Fallback generic error message for any other unexpected issues
      return res.status(500).json({
        success: false,
        message: "Database connection error. Please try again later.",
      });
    }
  },
);

module.exports = router;
