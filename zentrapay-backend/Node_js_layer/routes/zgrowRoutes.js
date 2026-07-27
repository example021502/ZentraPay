const express = require("express");
const router = express.Router();
const { authenticateToken } = require("../middleware/authMiddleware");
const apiClient = require("../utils/apiClient");

// ========================================================================
// ZGROW ROUTES - API DOCUMENTATION FOR FRONTEND
// ========================================================================
//
// Base URL: /api/zgrow
//
// ENDPOINTS:
// 1. GET  /api/zgrow/challenges              - Get active challenges
// 2. GET  /api/zgrow/challenges/category/{category} - Get challenges by category
// 3. POST /api/zgrow/challenges/{id}/join    - Join a challenge
// 4. GET  /api/zgrow/rewards                 - Get user's rewards
// 5. GET  /api/zgrow/literacy                - Get financial literacy content
// ========================================================================

/**
 * GET ACTIVE CHALLENGES
 * =====================
 *
 * @route GET /api/zgrow/challenges
 * @requires Authentication
 *
 * @returns {Array} challenges - List of active challenges
 */
router.get("/challenges", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zgrow/challenges", {
      userId: req.userId,
    });

    if (result.data && result.data.success) {
      return res.json({
        success: true,
        data: result.data.result,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.data?.message || "Failed to fetch challenges",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching challenges: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET CHALLENGES BY CATEGORY
 * ==========================
 *
 * @route GET /api/zgrow/challenges/category/:category
 * @requires Authentication
 *
 * @param {string} req.params.category - Category (SAVINGS, SPENDING, INVESTING)
 *
 * @returns {Array} challenges - List of challenges in category
 */
router.get(
  "/challenges/category/:category",
  authenticateToken,
  async (req, res) => {
    const { category } = req.params;

    try {
      const result = await apiClient.get(
        `/api/zgrow/challenges/category/${category}`,
        {
          userId: req.userId,
        },
      );

      if (result.data && result.data.success) {
        return res.json({
          success: true,
          data: result.data.result,
        });
      } else {
        return res.status(400).json({
          success: false,
          message:
            result.data?.message || "Failed to fetch challenges by category",
        });
      }
    } catch (e) {
      console.error("[NODE_JS] ERROR fetching challenges by category: ", e);
      return res.status(500).json({ success: false, message: "Server Error!" });
    }
  },
);

/**
 * JOIN A CHALLENGE
 * ================
 *
 * @route POST /api/zgrow/challenges/:challengeId/join
 * @requires Authentication
 *
 * @param {string} req.params.challengeId - Challenge ID to join
 *
 * @returns {Object} challenge - Updated challenge details
 */
router.post(
  "/challenges/:challengeId/join",
  authenticateToken,
  async (req, res) => {
    const { challengeId } = req.params;

    try {
      const result = await apiClient.post(
        `/api/zgrow/challenges/${challengeId}/join`,
        {
          userId: req.userId,
        },
      );

      if (result.data && result.data.success) {
        return res.json({
          success: true,
          data: result.data.result,
          message: result.data.message,
        });
      } else {
        return res.status(400).json({
          success: false,
          message: result.data?.message || "Failed to join challenge",
        });
      }
    } catch (e) {
      console.error("[NODE_JS] ERROR joining challenge: ", e);
      return res.status(500).json({ success: false, message: "Server Error!" });
    }
  },
);

/**
 * GET USER'S REWARDS
 * ==================
 *
 * @route GET /api/zgrow/rewards
 * @requires Authentication
 *
 * @returns {Object} rewards - User's rewards and points
 */
router.get("/rewards", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zgrow/rewards", {
      userId: req.userId,
    });

    if (result.data && result.data.success) {
      return res.json({
        success: true,
        data: result.data.result,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.data?.message || "Failed to fetch rewards",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching rewards: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

/**
 * GET FINANCIAL LITERACY CONTENT
 * ==============================
 *
 * @route GET /api/zgrow/literacy
 * @requires Authentication
 *
 * @returns {Array} content - Financial literacy articles/videos
 */
router.get("/literacy", authenticateToken, async (req, res) => {
  try {
    const result = await apiClient.get("/api/zgrow/literacy", {
      userId: req.userId,
    });

    if (result.data && result.data.success) {
      return res.json({
        success: true,
        data: result.data.result,
      });
    } else {
      return res.status(400).json({
        success: false,
        message: result.data?.message || "Failed to fetch literacy content",
      });
    }
  } catch (e) {
    console.error("[NODE_JS] ERROR fetching literacy content: ", e);
    return res.status(500).json({ success: false, message: "Server Error!" });
  }
});

module.exports = router;
