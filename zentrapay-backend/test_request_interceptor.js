/**
 * Test script for Request Interceptor Middleware
 * This demonstrates how the middleware intercepts and routes requests
 */

const express = require("express");
const requestInterceptor =
  require("./middleware/requestInterceptor").requestInterceptor;
const payStackProxy = require("./middleware/requestInterceptor").payStackProxy;
const appServerHandler =
  require("./middleware/requestInterceptor").appServerHandler;

const app = express();
app.use(express.json());

// Apply the request interceptor
app.use(requestInterceptor);

// Test PayStack route
app.post("/api/paystack/test", payStackProxy, (req, res) => {
  res.json({ message: "This should not be reached for PayStack routes" });
});

// Test App Server route
app.get("/api/users/test", appServerHandler, (req, res) => {
  res.json({
    message: "App server route handler",
    metadata: req.requestMetadata,
  });
});

// Start test server
const PORT = 3001;
app.listen(PORT, () => {
  console.log(`Test server running on port ${PORT}`);
  console.log("\nTest the middleware with these commands:");
  console.log(`\n1. Test PayStack route detection:`);
  console.log(
    `   curl -X POST http://localhost:${PORT}/api/paystack/test -H "Content-Type: application/json" -d '{}'`,
  );
  console.log(`\n2. Test App Server route detection:`);
  console.log(`   curl http://localhost:${PORT}/api/users/test`);
  console.log(`\n3. Test with authentication header:`);
  console.log(
    `   curl http://localhost:${PORT}/api/users/test -H "Authorization: Bearer test_token"`,
  );
  console.log(`\nPress Ctrl+C to stop the server\n`);
});
