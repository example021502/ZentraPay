// wallets, currency accounts, linked banks, balances
const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");

{
  /*
  ===============================================
  VIRTUAL CARDS ROUTE
  ===============================================
  */
}
router.get("/allCards", authenticateToken, async (req, res) => {
  const userId = req.userId;
  if (!userId) {
    return res.json({
      success: false,
      message: "User error. Try again",
    });
  }
  try {
    const response = await apiClient.get(`/api/cards/allCards`, {
      params: { userId },
    });
    console.log("ALL CARDS RESPONSE:: ", response.data);
    if (response.data && response.data.success) {
      return res.json({
        success: response.data.success || true,
        message: response.data.message || "Fetch successful",
        cards: response.data.data.cards,
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

module.exports = router;
