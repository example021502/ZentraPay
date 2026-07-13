const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });
const { Pool } = require("pg");

console.log(
  "DB_USER:",
  process.env.DB_USER,
  "type:",
  typeof process.env.DB_USER,
);
console.log(
  "DB_PASSWORD:",
  process.env.DB_PASSWORD,
  "type:",
  typeof process.env.DB_PASSWORD,
);
console.log("DB_PASSWORD value:", JSON.stringify(process.env.DB_PASSWORD));

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: String(process.env.DB_PASSWORD || ""),
  port: process.env.DB_PORT,
});

pool.on("connect", () => console.log("✓ Database connected successfully"));
pool.on("error", (err) => console.error("✗ Database error:", err.message));

async function testConnection() {
  try {
    const result = await pool.query("SELECT NOW()");
    console.log("✓ Test query successful:", result.rows[0]);
    await pool.end();
    console.log("✓ Connection closed");
    process.exit(0);
  } catch (err) {
    console.error("✗ Connection test failed:", err.message);
    process.exit(1);
  }
}

testConnection();
