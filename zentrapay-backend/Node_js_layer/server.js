const https = require("https");
const fs = require("fs");
const path = require("path");
require("dotenv").config();
const app = require("./app");
const config = require("./config/database");

const PORT = process.env.PORT || 3000;

// Start server

const httpsOptions = {
  key: fs.readFileSync(path.join(__dirname, "key.pem")),
  cert: fs.readFileSync(path.join(__dirname, "cert.pem")),
};
const server = https.createServer(httpsOptions, app);

server.listen(PORT, () => {
  console.log(`Awaresome, server is healthy and running, port: ${PORT}`);
});

// Graceful shutdown
process.on("SIGTERM", () => {
  console.log("SIGTERM signal received: closing HTTP server");
  server.close(() => {
    console.log("HTTP server closed");
    // Close database connection
    if (config.database) {
      config.database.end();
    }
    process.exit(0);
  });
});
