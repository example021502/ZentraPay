String extractCountryIsoCode(String currencyCode) {
  final String cleanCode = currencyCode.trim().toUpperCase();

  // 1. Handle rule-breaking currency codes explicitly
  const Map<String, String> currencyExceptions = {
    'EUR': 'EU', // Euro zone
    'BTC': 'US', // Bitcoin fallback
    'XOF': 'SN', // West African CFA franc (Senegal proxy)
    'XAF': 'CM', // Central African CFA franc (Cameroon proxy)
    'XCD': 'LC', // East Caribbean Dollar (St. Lucia proxy)
  };

  if (currencyExceptions.containsKey(cleanCode)) {
    return currencyExceptions[cleanCode]!;
  }

  // 2. Fallback to ISO 4217 standard rule: The first two letters are the country code
  if (cleanCode.length >= 2) {
    return cleanCode.substring(0, 2);
  }

  // 3. Absolute fallback safety valve
  return 'GH';
}
