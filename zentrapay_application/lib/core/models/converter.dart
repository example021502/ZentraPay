class RatesSnapshot {
  final String base;
  final Map<String, String> rates;

  RatesSnapshot({required this.base, required this.rates});

  factory RatesSnapshot.fromJson(Map<String, dynamic> json) => RatesSnapshot(
    base: json['base'] ?? '',
    rates: ((json['rates'] as Map?) ?? {}).map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    ),
  );
}

class ConversionResult {
  final String convertedAmount;
  final String rate;

  ConversionResult({required this.convertedAmount, required this.rate});

  factory ConversionResult.fromJson(Map<String, dynamic> json) =>
      ConversionResult(
        convertedAmount: (json['convertedAmount'] ?? '0').toString(),
        rate: (json['rate'] ?? '0').toString(),
      );
}

class ConversionHistoryEntry {
  final String fromCurrency;
  final String toCurrency;
  final String amount;
  final String convertedAmount;
  final String createdAt;

  ConversionHistoryEntry({
    required this.fromCurrency,
    required this.toCurrency,
    required this.amount,
    required this.convertedAmount,
    required this.createdAt,
  });

  factory ConversionHistoryEntry.fromJson(Map<String, dynamic> json) =>
      ConversionHistoryEntry(
        fromCurrency: json['fromCurrency'] ?? '',
        toCurrency: json['toCurrency'] ?? '',
        amount: (json['amount'] ?? '0').toString(),
        convertedAmount: (json['convertedAmount'] ?? '0').toString(),
        createdAt: json['createdAt'] ?? '',
      );
}
