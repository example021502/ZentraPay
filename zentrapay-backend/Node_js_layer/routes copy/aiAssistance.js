const express = require("express");
const router = express.Router();

// POST /api/ai/chat - Send message to AI assistant
router.post("/chat", (req, res) => {
  try {
    const { message } = req.body;

    if (!message) {
      return res.status(400).json({ error: "Message is required" });
    }

    // Simulate AI response
    const response = {
      message: "Hello there, how may i be of help today?",
      timestamp: new Date().toISOString(),
    };

    res.json(response);
  } catch (error) {
    res.status(500).json({ error: "Failed to process message" });
  }
});

// GET /api/ai/history - Get chat history
router.get("/history", (req, res) => {
  try {
    const chatHistory = [
      {
        id: 1,
        text: "Hello there, how may i be of help today?",
        isUser: false,
        time: "02 April 2022, 09:29",
      },
    ];

    res.json(chatHistory);
  } catch (error) {
    res.status(500).json({ error: "Failed to load chat history" });
  }
});

module.exports = router;
