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

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/features/wallet_topup/models/responseEntities.dart';

// ---------------------------------------------------------------------------
// Endpoints — align these with your Spring Boot controller that hosts fundWallet
// ---------------------------------------------------------------------------
const String _topupPaystackEndpoint = '/api/topup/paystack';
const String _topupFlutterwaveEndpoint = '/api/topup/flutterwave';
const String _kTopupVerifyPath = '/api/wallet/topup/verify/';

// ---------------------------------------------------------------------------
// Topup services
// ---------------------------------------------------------------------------
class TopupService {
  TopupService._();

  static final Dio _dio = ApiClient().dio;

  // ===============================================
  // PAYSTACK PUBLIC KEY
  // ===============================================
  static String get paystackPublicKey {
    return dotenv.get(
      'PAYSTACK_PUBLIC_KEY',
      fallback: dotenv.get('PAYSTACK_TEST_PK', fallback: ''),
    );
  }

  // =======================================
  // FLUTTERWAVE PUBLICK KEY
  // =======================================
  static String get flutterwavePK {
    return dotenv.get(
      'FLUTTERWAVE_PUBLIC_KEY',
      fallback: dotenv.get('FLUTTERWAVE_TEST_PK', fallback: ''),
    );
  }

  /// Initiate a wallet top-up. Creates the `PENDING` transaction (via your
  /// `fundWallet` backend) and asks the gateway to initialize the charge.
  ///
  /// [amount] is in major currency units (e.g. `100` for 100 GHS). The backend
  /// converts to minor units for the gateway.
  static Future<TopupResponse> topup({
    required double amount,
    required String currencyCode,
    required String source, // 'bank' | 'mobile_money'
    required String paymentMethod, // 'card' | 'bank_transfer' | 'mobile_money'
    String? phoneNumber,
    required String gateway,
  }) async {
    final response = await _dio.post(
      gateway.toLowerCase() == "paystack"
          ? _topupPaystackEndpoint
          : _topupFlutterwaveEndpoint,
      data: {
        'amount': amount,
        'currencyCode': currencyCode,
        'source': source,
        'paymentMethod': paymentMethod,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phoneNumber': phoneNumber,
      },
    );
    print("===== THE TOP UP REQUEST RESPONSE:: $response");
    return TopupResponse.fromJson(response.data as Map<String, dynamic>);
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
