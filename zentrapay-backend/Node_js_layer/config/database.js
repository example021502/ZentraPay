const path = require("path");
require("dotenv").config({ path: path.resolve(__dirname, "../.env") });

const { Pool } = require("pg");

const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_DATABASE,
  password: String(process.env.DB_PASSWORD),
  port: process.env.DB_PORT,
});

pool.on("connect", () => console.log("Database connected."));
pool.on("error", (err, client) => {
  console.error("Unexpected error on idle database client:", err);
  process.exit(-1);
});

module.exports = pool;
