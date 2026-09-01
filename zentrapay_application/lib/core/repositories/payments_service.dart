import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/gateway_customer_result.dart';
import 'package:zentrapay_application/core/models/paystack_new_customer_post.dart';
import 'package:zentrapay_application/core/models/flutterwave_new_customer_post.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/repositories/transactions_repository.dart';
import 'package:zentrapay_application/core/repositories/wallets_repository.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// Money-movement operations (internal transfer, bank disbursement, card
/// funding via Paystack). These aren't cached resources themselves — each
/// call is a deliberate user action — but every successful call updates the
/// two caches a payment affects (the sender's wallet balance and the
/// transaction history) instead of leaving other screens to refetch.
class PaymentsService {
  static final Dio _dio = ApiClient().dio;

  static Future<AppTransaction> payment({
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.post('/api/payments', data: payload);
    return _applyTransactionResult(response.data['data']);
  }

  static Future<AppTransaction> payBankTransfer({
    required String pin,
    required String amount,
    required String currencyCode,
    required String channelCode,
    required String accountNumber,
    required String accountName,
    String? description,
  }) async {
    final response = await _dio.post(
      '/api/payments/bank-transfer',
      data: {
        'pin': pin,
        'amount': amount,
        'currencyCode': currencyCode,
        'channelCode': channelCode,
        'accountNumber': accountNumber,
        'accountName': accountName,
        if (description != null) 'description': description,
      },
    );
    return _applyTransactionResult(response.data['data']);
  }

  static Future<Map<String, dynamic>> getPaystackAccessCode({
    required String amount,
    required String currencyCode,
  }) async {
    final response = await _dio.get(
      '/api/payments/paystack/access-code',
      queryParameters: {'amount': amount, 'currencyCode': currencyCode},
    );
    return response.data['data'] ?? {};
  }

  // ========================================================================
  // Customer creation — Paystack primary, Flutterwave failover
  // ========================================================================

  /// Creates a customer on the Paystack gateway via the backend proxy.
  ///
  /// The backend forwards [request] to Paystack's `POST /v1/customers`
  /// endpoint (using the stored secret key) and unwraps the `data` envelope
  /// for the caller.
  static Future<PaystackCustomerResponse> createPaystackCustomer({
    required PaystackNewCustomerPost request,
  }) async {
    final response = await _dio.post(
      '/api/payments/paystack/customer',
      data: request.toJson(),
    );
    return PaystackCustomerResponse.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  /// Creates a customer on the Flutterwave gateway via the backend proxy.
  ///
  /// Mirror of [createPaystackCustomer] but targeting Flutterwave's
  /// `POST /v3/customers` endpoint (also uses the stored secret key on the
  /// backend).
  static Future<FlutterwaveCustomerResponse> createFlutterwaveCustomer({
    required FlutterwaveNewCustomerPost request,
  }) async {
    final response = await _dio.post(
      '/api/payments/flutterwave/customer',
      data: request.toJson(),
    );
    return FlutterwaveCustomerResponse.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }

  /// Creates a gateway customer with automatic failover.
  ///
  /// Tries Paystack first (the primary Ghanaian-national gateway per the
  /// architecture docs). If the Paystack call throws — timeout, 4xx/5xx, or
  /// any other [DioException] — it immediately retries via Flutterwave as
  /// the secondary/failover gateway, ensuring 99.9% uptime per the DEPLOYMENT
  /// GUIDE.
  ///
  /// Returns a normalised [GatewayCustomerResult] that records which gateway
  /// ultimately succeeded so the caller can surface it "for transparency"
  /// (see Failover Strategy §2 in the deployment guide).
  static Future<GatewayCustomerResult> createCustomerWithFailover({
    required String email,
    String? firstName,
    String? lastName,
    String? phone,
    Map<String, dynamic>? metadata,
  }) async {
    // Build the same set of identity fields for both gateways.
    final paystackRequest = PaystackNewCustomerPost(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      metadata: metadata,
    );
    final flutterwaveRequest = FlutterwaveNewCustomerPost(
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      // Flutterwave uses "meta" rather than "metadata" — map the same blob.
      meta: metadata,
    );

    // --- Primary: Paystack ------------------------------------------------
    try {
      final response = await createPaystackCustomer(request: paystackRequest);
      return GatewayCustomerResult(
        gateway: 'paystack',
        customerId: response.code,
        email: response.email,
        displayName: _joinName(response.firstName, response.lastName),
        phone: response.phone,
      );
    } on DioException catch (e) {
      // Paystack failed — log and fall through to Flutterwave.
      debugPrint(
        'Paystack customer creation failed (status '
        '${e.response?.statusCode}), failing over to Flutterwave: '
        '${e.message}',
      );
    } catch (e) {
      // Non-DioException (e.g. parsing error) — also fall through.
      debugPrint('Paystack customer creation failed unexpectedly: $e');
    }

    // --- Failover: Flutterwave --------------------------------------------
    final response = await createFlutterwaveCustomer(
      request: flutterwaveRequest,
    );
    return GatewayCustomerResult(
      gateway: 'flutterwave',
      customerId: response.id ?? '',
      email: response.email,
      displayName: _joinName(response.firstName, response.lastName),
      phone: response.phone,
    );
  }

  /// Joins first/last name into a display string, returning null when both
  /// are absent (mirrors the "best-effort" nature of the gateway response).
  static String? _joinName(String? first, String? last) {
    final f = first?.trim();
    final l = last?.trim();
    if ((f == null || f.isEmpty) && (l == null || l.isEmpty)) return null;
    return '$f $l'.trim();
  }

  static AppTransaction _applyTransactionResult(Map<String, dynamic> json) {
    final transaction = AppTransaction.fromJson(json);
    TransactionsRepository.instance.prepend(transaction);
    // The wallet's balance changed server-side; the cheapest correct move
    // is a forced refresh of the (already-loaded) wallets snapshot rather
    // than trying to recompute the new balance client-side.
    WalletsRepository.instance.ensureLoaded();
    return transaction;
  }
}
