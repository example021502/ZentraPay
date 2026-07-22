const express = require("express");
const router = express.Router();

/**
 * ZGrow Routes
 * Financial Wellness Hub - gamified savings, rewards, literacy videos, AI coach
 */

// Get financial health score
router.get("/health-score", (req, res) => {
  res.json({
    success: true,
    data: {
      score: 86.7,
      level: "Excellent",
      breakdown: {
        savings: 90,
        spending: 85,
        investments: 80,
        debt: 92,
      },
      nextMilestone: "Your next Milestone unlocks in 3 days",
    },
  });
});

// Get savings challenges
router.get("/challenges", (req, res) => {
  res.json({
    success: true,
    data: {
      activeChallenges: [
        {
          id: "challenge_001",
          name: "30-Day No Spend Challenge",
          progress: 65,
          reward: "GHS 50 bonus",
          daysRemaining: 10,
        },
        {
          id: "challenge_002",
          name: "Save GHS 500 This Month",
          progress: 80,
          reward: "GHS 25 bonus",
          daysRemaining: 5,
        },
      ],
      completedChallenges: 12,
    },
  });
});

// Get rewards
router.get("/rewards", (req, res) => {
  res.json({
    success: true,
    data: {
      points: 2500,
      tier: "Gold",
      availableRewards: [
        { id: "reward_001", name: "GHS 10 Cashback", points: 1000 },
        { id: "reward_002", name: "Free Transfer", points: 500 },
        { id: "reward_003", name: "Premium Feature Unlock", points: 2000 },
      ],
    },
  });
});

// Get finance literacy content
router.get("/learn", (req, res) => {
  res.json({
    success: true,
    data: {
      videos: [
        {
          id: "video_001",
          title: "Understanding Savings",
          duration: "5 min",
          category: "Basics",
        },
        {
          id: "video_002",
          title: "Investing for Beginners",
          duration: "10 min",
          category: "Investing",
        },
        {
          id: "video_003",
          title: "Budgeting Tips",
          duration: "7 min",
          category: "Budgeting",
        },
      ],
      articles: [
        { id: "article_001", title: "5 Ways to Save More", readTime: "3 min" },
        { id: "article_002", title: "Crypto Basics", readTime: "8 min" },
      ],
    },
  });
});

// Get milestones
router.get("/milestones", (req, res) => {
  res.json({
    success: true,
    data: {
      milestones: [
        {
          id: "ms_001",
          name: "First GHS 1,000 Saved",
          achieved: true,
          date: "2026-06-01",
        },
        {
          id: "ms_002",
          name: "First Investment",
          achieved: true,
          date: "2026-06-15",
        },
        {
          id: "ms_003",
          name: "GHS 5,000 Portfolio",
          achieved: false,
          progress: 74,
        },
        { id: "ms_004", name: "100 Day Streak", achieved: false, progress: 65 },
      ],
    },
  });
});

// AI coach chat
router.post("/ai-coach", (req, res) => {
  const { message } = req.body;
  res.json({
    success: true,
    data: {
      response:
        "Based on your spending patterns, I recommend setting aside 20% of your income for savings. You're currently at 15%.",
      suggestions: [
        "Set up automatic savings",
        "Reduce dining out expenses",
        "Consider micro-investments",
      ],
    },
  });
});

module.exports = router;
