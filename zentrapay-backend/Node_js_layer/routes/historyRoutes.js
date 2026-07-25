const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");

router.get("/searchContacts", authenticateToken, async (req, res) => {
  const { query } = req.params;
  try {
    console.log("QUERY:: ", query);
    const contacts = await apiClient.get(`/api/searchContacts/${query}`);
    console.log("CONTACTS AFTER SEARCHING ARE: ", contacts);
    if (contacts.data && contacts.data.success) {
      return res.json({
        success: data.success,
        contacts: contacts.data.contacts,
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
