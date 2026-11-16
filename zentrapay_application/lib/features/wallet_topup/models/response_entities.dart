// ignore: file_names
class TopupResponse {
  /// Internal reference, e.g. `ZP_DEP_99201` (used for idempotency & verify).
  final String reference;

  /// Backend transaction status: PENDING / SUCCESS / FAILED.
  final bool status;

  /// Human message from the backend.
  final String message;

  /// Payment method selected: `card` | `bank_transfer` | `mobile_money`.
  final String? paymentMethod;

  /// Card / checkout redirect URL (returned by the gateway initialize charge).
  final String? authorizationUrl;

  /// Paystack `access_code` used to launch the Paystack Flutter SDK charge UI.
  final String? accessCode;

  /// Bank-transfer details returned by the gateway (virtual account), if any.
  final Map<String, dynamic>? virtualAccount;

  /// Mobile-money prompt info returned by the gateway, if any.
  final Map<String, dynamic>? mobileMoney;

  /// Any extra gateway payload the backend chose to return.
  final Map<String, dynamic>? gatewayData;

  TopupResponse({
    required this.reference,
    required this.status,
    this.message = '',
    this.paymentMethod,
    this.authorizationUrl,
    this.accessCode,
    this.virtualAccount,
    this.mobileMoney,
    this.gatewayData,
  });

  factory TopupResponse.fromJson(Map<String, dynamic> json) {
    return TopupResponse(
      reference: (json['reference'] ?? json['ref'] ?? '') as String,
      status: (json['status'] ?? false) as bool,
      message: (json['message'] ?? '') as String,
      paymentMethod: json['paymentMethod'] as String?,
      authorizationUrl: json['authorizationUrl'] as String?,
      accessCode: json['accessCode'] as String?,
      virtualAccount: json['virtualAccount'] != null
          ? Map<String, dynamic>.from(json['virtualAccount'] as Map)
          : null,
      mobileMoney: json['mobileMoney'] != null
          ? Map<String, dynamic>.from(json['mobileMoney'] as Map)
          : null,
      gatewayData: json['gatewayData'] != null
          ? Map<String, dynamic>.from(json['gatewayData'] as Map)
          : null,
    );
  }
}

/// Backend response when a top-up reference is verified.
class TopupVerifyResponse {
  final String reference;
  final String status;
  final num amount;
  final String currency;
  final String message;

  TopupVerifyResponse({
    required this.reference,
    required this.status,
    required this.amount,
    required this.currency,
    this.message = '',
  });

  bool get isSuccess =>
      status.toUpperCase() == 'SUCCESS' || status.toUpperCase() == 'COMPLETED';

  factory TopupVerifyResponse.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'] ?? 0;
    final parsed = rawAmount is num
        ? rawAmount
        : num.tryParse(rawAmount.toString()) ?? 0;
    return TopupVerifyResponse(
      reference: (json['reference'] ?? '') as String,
      status: (json['status'] ?? 'PENDING') as String,
      amount: parsed,
      currency: (json['currency'] ?? 'GHS') as String,
      message: (json['message'] ?? '') as String,
    );
  }
}
