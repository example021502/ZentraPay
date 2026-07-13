const express = require("express");
const router = express.Router();

// POST /api/voice/start - Start voice recording
router.post("/start", (req, res) => {
  try {
    const response = {
      recordingId: Date.now(),
      status: "recording",
      message: "Voice recording started",
    };

    res.json(response);
  } catch (error) {
    res.status(500).json({ error: "Failed to start recording" });
  }
});

// POST /api/voice/stop - Stop voice recording
router.post("/stop", (req, res) => {
  try {
    const response = {
      recordingId: Date.now(),
      status: "stopped",
      audioPath: "/recordings/recording_" + Date.now() + ".wav",
      duration: "0:05",
    };

    res.json(response);
  } catch (error) {
    res.status(500).json({ error: "Failed to stop recording" });
  }
});

// POST /api/voice/process - Process voice command
router.post("/process", (req, res) => {
  try {
    const { audioPath } = req.body;

    if (!audioPath) {
      return res.status(400).json({ error: "Audio path is required" });
    }

    const response = {
      command: "transfer_money",
      confidence: 0.95,
      parameters: {
        amount: 100,
        currency: "GHS",
        recipient: "John Doe",
      },
    };

    res.json(response);
  } catch (error) {
    res.status(500).json({ error: "Failed to process voice command" });
  }
});

module.exports = router;
