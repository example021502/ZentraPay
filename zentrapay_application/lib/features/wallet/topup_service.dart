/// Wallet top-up API client.
///
/// The card / bank-transfer / mobile-money business logic — creating the
/// `PENDING` transaction record, calling the gateway (Paystack / Flutterwave),
/// verifying webhooks and crediting the wallet + ledger — lives in your Spring
/// Boot backend's `fundWallet` method. This Flutter layer only:
///   1. Asks the backend to INITIATE a top-up (returns a reference + gateway data).
///   2. Launches the Paystack card UI when the method is `card`.
///   3. Asks the backend to VERIFY a reference after the customer pays.
///
/// Wire the two endpoints below to the controller methods that wrap your
/// `fundWallet` logic.

library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

// ---------------------------------------------------------------------------
// Endpoints — align these with your Spring Boot controller that hosts fundWallet
// ---------------------------------------------------------------------------
const String _kTopupInitiatePath = '/api/wallet/topup/initiate';
const String _kTopupVerifyPath = '/api/wallet/topup/verify/';

// ---------------------------------------------------------------------------
// Response models
// ---------------------------------------------------------------------------

/// Backend response when a top-up is initiated.
class TopupInitResponse {
  /// Internal reference, e.g. `ZP_DEP_99201` (used for idempotency & verify).
  final String reference;

  /// Backend transaction status: PENDING / SUCCESS / FAILED.
  final String status;

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

  TopupInitResponse({
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

  factory TopupInitResponse.fromJson(Map<String, dynamic> json) {
    return TopupInitResponse(
      reference: (json['reference'] ?? json['ref'] ?? '') as String,
      status: (json['status'] ?? 'PENDING') as String,
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
      status.toUpperCase() == 'SUCCESS' ||
      status.toUpperCase() == 'COMPLETED';

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

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class TopupService {
  TopupService._();

  static final Dio _dio = ApiClient().dio;

  /// Paystack public key from `.env`. Falls back to the test key so the card
  /// flow works in development. Switch to the live key in production.
  static String get paystackPublicKey {
    return dotenv.get('PAYSTACK_PUBLIC_KEY',
            fallback: dotenv.get('PAYSTACK_TEST_PK', fallback: '')) as String;
  }

  /// Initiate a wallet top-up. Creates the `PENDING` transaction (via your
  /// `fundWallet` backend) and asks the gateway to initialize the charge.
  ///
  /// [amount] is in major currency units (e.g. `100` for 100 GHS). The backend
  /// converts to minor units for the gateway.
  static Future<TopupInitResponse> initiate({
    required double amount,
    required String currencyCode,
    required String source, // 'bank' | 'mobile_money'
    required String paymentMethod, // 'card' | 'bank_transfer' | 'mobile_money'
    String? phoneNumber,
  }) async {
    final response = await _dio.post(
      _kTopupInitiatePath,
      data: {
        'amount': amount,
        'currencyCode': currencyCode,
        'source': source,
        'paymentMethod': paymentMethod,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
      },
    );
    return TopupInitResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Verify a top-up reference server-side (re-confirms with the gateway and
  /// returns the ledgered status). Call this after the customer completes
  /// payment (Paystack success, bank transfer alert, MoMo confirmation).
  static Future<TopupVerifyResponse> verify(String reference) async {
    final response = await _dio.get('$_kTopupVerifyPath$reference');
    return TopupVerifyResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Turns a thrown error into a customer-safe message.
  static String friendlyError(Object? error) {
    try {
      return _safeErrorMessage(error);
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  static String _safeErrorMessage(Object? error) {
    if (error is DioException) {
      final body = error.response?.data;
      if (body is Map && body['message'] is String) {
        return body['message'] as String;
      }
      if (error.response == null) {
        return 'We couldn\'t reach Zentrapay. Check your internet connection.';
      }
      return 'Something went wrong. Please try again.';
    }
    final text = error.toString();
    return text.isEmpty ? 'Something went wrong. Please try again.' : text;
  }
}
