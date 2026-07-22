const express = require("express");
const router = express.Router();

// GET /api/milestones/goals - Get all goals
router.get("/goals", (req, res) => {
  try {
    const goals = [
      {
        id: 1,
        name: "New Macbook Computer",
        target: 1728.28,
        saved: 1728.28,
        icon: "laptop_mac",
        autoSave: true,
      },
      {
        id: 2,
        name: "New House",
        target: 2530.0,
        saved: 2530.0,
        icon: "home",
        autoSave: true,
      },
    ];

    res.json(goals);
  } catch (error) {
    res.status(500).json({ error: "Failed to load goals" });
  }
});

// POST /api/milestones/goals - Create new goal
router.post("/goals", (req, res) => {
  try {
    const { name, target, saved, icon, autoSave } = req.body;

    if (!name || !target) {
      return res.status(400).json({ error: "Name and target are required" });
    }

    const newGoal = {
      id: Date.now(),
      name,
      target,
      saved: saved || 0,
      icon: icon || "savings",
      autoSave: autoSave || false,
    };

    res.status(201).json(newGoal);
  } catch (error) {
    res.status(500).json({ error: "Failed to create goal" });
  }
});

// PUT /api/milestones/goals/:id - Update goal
router.put("/goals/:id", (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body;

    const updatedGoal = {
      id: parseInt(id),
      ...updates,
    };

    res.json(updatedGoal);
  } catch (error) {
    res.status(500).json({ error: "Failed to update goal" });
  }
});

// DELETE /api/milestones/goals/:id - Delete goal
router.delete("/goals/:id", (req, res) => {
  try {
    const { id } = req.params;

    res.json({ message: "Goal deleted successfully", id: parseInt(id) });
  } catch (error) {
    res.status(500).json({ error: "Failed to delete goal" });
  }
});

module.exports = router;
