class TransactionResponse {
  final String status;
  final String message;
  final String reference;

  TransactionResponse(
      {required this.status, required this.message, required this.reference});

  factory TransactionResponse.fromMap(Map<dynamic, dynamic> map) {
    return TransactionResponse(
      status: map['status'] as String,
      message: map['message'] as String,
      reference: map['reference'] as String,
    );
  }
}

class PaystackException implements Exception {
  final String message;
  final String code;
  final dynamic details;

  PaystackException({required this.message, required this.code, this.details});

  @override
  String toString() => 'PaystackException: $message (code: $code)';
}
