const logger = {
  info: (message, meta = {}) => {
    console.log(
      `[INFO] ${new Date().toISOString()} - ${message}`,
      JSON.stringify(meta),
    );
  },

  error: (message, error = null) => {
    console.error(
      `[ERROR] ${new Date().toISOString()} - ${message}`,
      error ? error.stack || error : "",
    );
  },

  warn: (message, meta = {}) => {
    console.warn(
      `[WARN] ${new Date().toISOString()} - ${message}`,
      JSON.stringify(meta),
    );
  },

  debug: (message, meta = {}) => {
    if (process.env.NODE_ENV === "development") {
      console.debug(
        `[DEBUG] ${new Date().toISOString()} - ${message}`,
        JSON.stringify(meta),
      );
    }
  },
};

module.exports = logger;
