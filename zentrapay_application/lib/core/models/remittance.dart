class RemittanceRecord {
  final String remittanceId;
  final String amount;
  final String sourceCurrencyCode;
  final String destinationCurrencyCode;
  final String recipientName;
  final String status;
  final String createdAt;

  RemittanceRecord({
    required this.remittanceId,
    required this.amount,
    required this.sourceCurrencyCode,
    required this.destinationCurrencyCode,
    required this.recipientName,
    required this.status,
    required this.createdAt,
  });

  factory RemittanceRecord.fromJson(Map<String, dynamic> json) =>
      RemittanceRecord(
        remittanceId: json['remittanceId'] ?? '',
        amount: (json['amount'] ?? '0').toString(),
        sourceCurrencyCode: json['sourceCurrencyCode'] ?? '',
        destinationCurrencyCode: json['destinationCurrencyCode'] ?? '',
        recipientName: json['recipientName'] ?? '',
        status: json['status'] ?? '',
        createdAt: json['createdAt'] ?? '',
      );
}

class RemittanceQuote {
  final String exchangeRate;
  final String fee;

  RemittanceQuote({required this.exchangeRate, required this.fee});

  factory RemittanceQuote.fromJson(Map<String, dynamic> json) =>
      RemittanceQuote(
        exchangeRate: (json['exchangeRate'] ?? '0').toString(),
        fee: (json['fee'] ?? '0').toString(),
      );
}
