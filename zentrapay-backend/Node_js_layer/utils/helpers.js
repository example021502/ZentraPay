const helpers = {
  generateTransactionId: () => {
    return `TXN-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  },

  formatCurrency: (amount, currency = "GHS") => {
    return new Intl.NumberFormat("en-GH", {
      style: "currency",
      currency: currency,
    }).format(amount);
  },

  sanitizeInput: (input) => {
    if (typeof input !== "string") return input;
    return input.trim().replace(/[<>]/g, "");
  },

  validateEmail: (email) => {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  },

  validatePhone: (phone) => {
    const re = /^\+?[1-9]\d{1,14}$/;
    return re.test(phone);
  },
};

module.exports = helpers;
