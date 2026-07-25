const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");

router.post("/internal", authenticateToken, async (req, res) => {
  const { amount, pin, phone_number, zentag, currency_code } = req.body;
  const user_id = req.userId;
  if (!amount || !pin || (!phone_number && !zentag) || !currency_code) {
    return res.json({
      success: false,
      message: "Value Error",
    });
  }
  if (!user_id) {
    return res.json({ success: false, message: "User Error!" });
  }
  try {
    const result = apiClient.get(`/api/payments/internal`, {
      userId: user_id,
      amount: amount,
      currencyCode: currency_code,
      phoneNumber: phone_number,
      zentag: zentag,
      PIN: pin,
    });
    console.log("payment results: ", result);
    if (result.data && result.data.success) {
      return res.json({
        success: data.success,
        result: result.data.paymentDetails,
      });
    } else {
      return res.json({
        success: contacts.data.success || false,
        message: contacts.data.message || "Something went wrong",
      });
    }
  } catch (e) {
    console.log("ERROR SEARCHING: ", e);
    return res.json({ success: false, message: "Network Error!" });
  }
});

module.exports = router;
