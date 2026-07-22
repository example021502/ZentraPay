const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const jwt = require("jsonwebtoken");
const jwt_secret = process.env.JWT_SECRET_KEY;

// JWT Authentication Middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];

  // Verify the header exists and explicitly starts with 'Bearer ' (case-insensitive check)
  if (!authHeader || !authHeader.toLowerCase().startsWith("bearer ")) {
    return res
      .status(401)
      .json({ success: false, message: "Access Denied! No token provided." });
  }

  // Extract the raw token string reliably
  const token = authHeader.split(" ")[1];

  jwt.verify(token, jwt_secret, (err, decoded) => {
    if (err) {
      // Check if the error is specifically due to token expiration
      if (err.name === "TokenExpiredError") {
        return res
          .status(401)
          .json({ success: false, message: "Token has expired!" });
      }
      return res
        .status(403)
        .json({ success: false, message: "Invalid Token!" });
    }

    // Attach decoded user info to request object safely
    req.userId = decoded.user_id;
    next();
  });
};

module.exports = {
  authenticateToken,
};
