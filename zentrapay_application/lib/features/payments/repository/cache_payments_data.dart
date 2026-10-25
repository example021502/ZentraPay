import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/converter.dart';
import 'package:zentrapay_application/core/models/flutterwave_new_customer_post.dart';
import 'package:zentrapay_application/core/models/gateway_customer_result.dart';
import 'package:zentrapay_application/core/models/paystack_new_customer_post.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';

/// Payments data caches: converter rates/history, the currency-conversion
/// service and the money-movement operations (PaymentsService). Every
/// cached resource implements the "load once, then apply deltas" contract
/// inline — there is no shared abstract cache base anymore; each repository
/// owns its own state and notifies listeners.
///
/// The ZRemit screen imports this file for the live exchange-rate header,
/// and the transfer flows use [PaymentsService].

/// Exchange-rate snapshot for a base currency (`GET /api/converter/rates`).
class RatesRepository extends ChangeNotifier {
  RatesRepository._();
  static final RatesRepository instance = RatesRepository._();

  final Dio _dio = ApiClient().dio;
  String _base = 'GHS';

  RatesSnapshot? _data;
  bool _loading = false;
  Object? _error;

  RatesSnapshot? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// Rates for a given base currency are cached independently — switching
  /// base currency in the UI is a deliberate refetch, not a cache miss on
  /// the same resource.
  Future<RatesSnapshot?> loadForBase(String base) {
    if (base != _base) clear();
    _base = base;
    return ensureLoaded();
  }

  /// The actual network call.
  Future<RatesSnapshot> fetch() async {
    final response = await _dio.get(
      '/api/converter/rates',
      queryParameters: {'base': _base},
    );
    return RatesSnapshot.fromJson(response.data['data']);
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<RatesSnapshot?> ensureLoaded({bool forceRefresh = false}) async {
    if (_data != null && !forceRefresh) return _data;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await fetch();
      return _data;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Applies a POST/PUT response onto the cached value without refetching.
  void applyDelta(RatesSnapshot Function(RatesSnapshot current) updater) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(RatesSnapshot value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Conversion history (`GET /api/converter/history`). List cache.
class ConverterHistoryRepository extends ChangeNotifier {
  ConverterHistoryRepository._();
  static final ConverterHistoryRepository instance =
      ConverterHistoryRepository._();

  final Dio _dio = ApiClient().dio;

  List<ConversionHistoryEntry>? _data;
  bool _loading = false;
  Object? _error;

  List<ConversionHistoryEntry>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  /// The actual network call.
  Future<List<ConversionHistoryEntry>> fetch() async {
    final response = await _dio.get('/api/converter/history');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => ConversionHistoryEntry.fromJson(e))
        .toList();
  }

  /// Loads the resource the first time it's needed; subsequent calls are a
  /// no-op unless [forceRefresh] is set (pull-to-refresh, explicit retry).
  Future<List<ConversionHistoryEntry>?> ensureLoaded({
    bool forceRefresh = false,
  }) async {
    if (_data != null && !forceRefresh) return _data;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await fetch();
      return _data;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Applies a POST/PUT response onto the cached value without refetching.
  void applyDelta(
    List<ConversionHistoryEntry> Function(List<ConversionHistoryEntry> current)
    updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(List<ConversionHistoryEntry> value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// List convenience mutators.
  void addItem(ConversionHistoryEntry item) =>
      applyDelta((current) => [...current, item]);

  void replaceItem(
    bool Function(ConversionHistoryEntry item) matches,
    ConversionHistoryEntry replacement,
  ) {
    applyDelta(
      (current) => [
        for (final item in current) matches(item) ? replacement : item,
      ],
    );
  }

  void removeItem(bool Function(ConversionHistoryEntry item) matches) {
    applyDelta((current) => current.where((item) => !matches(item)).toList());
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}

/// Currency conversion operations. Not a cached resource — each call is a
/// deliberate user action — but a conversion changes server-side history,
/// so the history cache is cleared to refresh lazily next time it's opened.
class ConverterService {
  static final Dio _dio = ApiClient().dio;

  static Future<ConversionResult> convert({
    required String from,
    required String to,
    required String amount,
  }) async {
    final response = await _dio.post(
      '/api/converter/convert',
      data: {'from': from, 'to': to, 'amount': amount},
    );
    final result = ConversionResult.fromJson(response.data['data']);
    // A conversion changes server-side history — refresh lazily next time
    // the history screen is opened rather than forcing a refetch now.
    ConverterHistoryRepository.instance.clear();
    return result;
  }
}

/// Money-movement operations (internal transfer, bank disbursement, card
/// funding via Paystack). These aren't cached resources themselves — each
/// call is a deliberate user action — but every successful call updates the
/// two caches a payment affects (the sender's wallet balance and the
/// transaction history) instead of leaving other screens to refetch.
class PaymentsService {
  static final Dio _dio = ApiClient().dio;

  static Future<Map<String, dynamic>> payment({
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.post('/api/payments/initialize', data: payload);
    final String message = response.data['message'] ?? 'Payment successful';
    if (response.data['success'] == true && response.data['data'] != null) {
      // _applyTransactionResult hands back the parsed AppTransaction; the
      // caller used to receive the RAW response map here and then cast it
      // `as AppTransaction?` — a TypeError that surfaced as "Payment Failed"
      // even though the backend had already committed the transfer.
      final AppTransaction transaction = _applyTransactionResult(
        response.data['data'],
      );
      return {'data': transaction, 'message': message};
    } else {
      return {
        'data': null,
        'message': 'Payment response missing transaction data',
      };
    }
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
        'description': ?description,
      },
    );
    if (response.data['data'] == null) {
      throw Exception('Bank transfer response missing transaction data');
    }
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
  ///
  /// Throws a detailed [GatewayError] if both gateways fail.
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
    GatewayCustomerResult? paystackResult;
    try {
      final response = await createPaystackCustomer(request: paystackRequest);
      paystackResult = GatewayCustomerResult(
        gateway: 'paystack',
        customerId: response.code,
        email: response.email,
        displayName: _joinName(response.firstName, response.lastName),
        phone: response.phone,
      );
      // Save Paystack customer to secure storage immediately, even before
      // returning success — allows recovery on the webhook callback.
      await _saveCustomerToSecureStorage(paystackResult);
      return paystackResult;
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
    GatewayCustomerResult? flutterwaveResult;
    try {
      final response = await createFlutterwaveCustomer(
        request: flutterwaveRequest,
      );
      flutterwaveResult = GatewayCustomerResult(
        gateway: 'flutterwave',
        customerId: response.id ?? '',
        email: response.email,
        displayName: _joinName(response.firstName, response.lastName),
        phone: response.phone,
      );
      // Save Flutterwave customer to secure storage immediately.
      await _saveCustomerToSecureStorage(flutterwaveResult);
      return flutterwaveResult;
    } on DioException catch (e) {
      debugPrint(
        'Flutterwave customer creation failed (status '
        '${e.response?.statusCode}): ${e.message}',
      );
    } catch (e) {
      debugPrint('Flutterwave customer creation failed unexpectedly: $e');
    }

    // --- Both gateways failed ------------------------------------------------
    final errors = [];
    if (paystackResult == null) {
      errors.add('Paystack: customer creation failed');
    }
    if (flutterwaveResult == null) {
      errors.add('Flutterwave: customer creation failed');
    }
    throw GatewayError(
      message: 'Both payment gateways failed. Errors: ${errors.join('; ')}',
      gatewaysUsed: ['paystack', 'flutterwave'],
      details: {
        'paystackError': paystackResult == null ? 'failed' : null,
        'flutterwaveError': flutterwaveResult == null ? 'failed' : null,
      },
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

  /// Saves the gateway customer result to secure storage so the data is
  /// available across sessions and for webhook callback processing.
  static Future<void> _saveCustomerToSecureStorage(
    GatewayCustomerResult result,
  ) async {
    try {
      await SecureStorageService.saveCustomer(
        gateway: result.gateway,
        customerId: result.customerId,
        email: result.email,
        displayName: result.displayName ?? '',
        phone: result.phone ?? '',
        metadata: {
          'userId': SecureStorageService.getUserId() ?? '',
          'createdAt': DateTime.now().toIso8601String(),
          // The customer payload is stored as plain JSON primitives — the
          // storage layer encodes it, and model instances are not
          // JSON-encodable.
          'customerGateway': result.gateway,
          'customerId': result.customerId,
          'email': result.email,
          'displayName': result.displayName ?? '',
          'phone': result.phone ?? '',
        },
      );
    } catch (e) {
      debugPrint('Failed to save customer data to secure storage: $e');
      // Don't throw - secure storage failure shouldn't block the main flow.
    }
  }

  /// Retrieves the gateway customer result from secure storage.
  static Future<GatewayCustomerResult?> getCustomerFromSecureStorage() async {
    try {
      final Map<String, String>? data =
          await SecureStorageService.getCustomer();
      if (data == null) return null;

      final String displayName = data['displayName'] ?? '';
      final String phone = data['phone'] ?? '';
      return GatewayCustomerResult(
        gateway: data['gateway'] ?? '',
        customerId: data['customerId'] ?? '',
        email: data['email'] ?? '',
        displayName: displayName.isEmpty ? null : displayName,
        phone: phone.isEmpty ? null : phone,
      );
    } catch (e) {
      debugPrint('Failed to read customer data from secure storage: $e');
      return null;
    }
  }

  /// Clears the saved customer data from secure storage.
  static Future<void> clearCustomerFromSecureStorage() async {
    try {
      await SecureStorageService.clearCustomer();
    } catch (e) {
      debugPrint('Failed to clear customer data from secure storage: $e');
    }
  }

  /// Parses a transaction payload, prepends it to the cached transaction
  /// history and refreshes the wallet snapshot.
  static AppTransaction _applyTransactionResult(Map<String, dynamic> json) {
    final transaction = AppTransaction.fromJson(json);
    TransactionsRepository.instance.prepend(transaction);
    // The wallet's balance changed server-side; the cheapest correct move
    // is a forced refresh of the (already-loaded) wallets snapshot rather
    // than trying to recompute the new balance client-side.
    WalletsRepository.instance.ensureLoaded();
    return transaction;
  }

  // ============================================================================
  // Webhook Callback Handlers — Payment Confirmation Flow
  // ============================================================================

  /// Handles webhook callbacks from payment gateways when a payment
  /// transaction reaches a terminal state (success, failed, expired).
  static Future<void> handlePaymentWebhook({
    required String gateway,
    required String transactionId,
    required String status,
    String? reference,
    String? receiverId,
    String? receiverName,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate required fields
    if (transactionId.isEmpty) {
      debugPrint('Webhook error: missing transactionId');
      return;
    }

    // Normalize status
    final normalizedStatus = status.trim().toUpperCase();

    // Handle status-specific logic
    switch (normalizedStatus) {
      case 'SUCCESS':
        debugPrint('Webhook: Transaction $transactionId marked as SUCCESS');
        final refToUse = reference ?? transactionId;
        final Map<String, dynamic> transactionData = {
          'transactionId': transactionId,
          'TXN_Ref': refToUse,
          'receiverId': receiverId ?? '',
          'destinationId': receiverId ?? '',
          'amount': metadata?['amount']?.toString() ?? '',
          'status': normalizedStatus,
          'receiverName': receiverName ?? '',
          'completedAt':
              metadata?['completedAt']?.toString() ??
              DateTime.now().toIso8601String(),
          'transactionType':
              metadata?['transactionType']?.toString() ?? 'EXTERNAL',
        };
        _applyTransactionResult(transactionData);
        debugPrint('Webhook: Transaction $transactionId confirmed');
        break;

      case 'FAILED':
      case 'EXPIRED':
        debugPrint(
          'Webhook: Transaction $transactionId marked as $normalizedStatus',
        );
        break;

      case 'PENDING':
        debugPrint('Webhook: Transaction $transactionId still PENDING');
        break;

      default:
        debugPrint(
          'Webhook: Unrecognized status "$status" for transaction $transactionId',
        );
    }
  }

  /// Processes a Paystack webhook callback.
  static Future<void> handlePaystackWebhook(
    Map<String, dynamic> payload,
  ) async {
    final String? eventType = payload['event_type']?.toString();
    final Map<String, dynamic>? data = payload['data'];

    debugPrint('Paystack webhook received: $eventType');

    switch (eventType) {
      case 'customer.created':
        debugPrint('Paystack customer created: ${data?['id']}');
        break;

      case 'payment.created':
      case 'payment.updated':
        final String? transactionId = data?['id']?.toString();
        final String? status = data?['status']?.toString();
        if (transactionId != null && status != null) {
          await handlePaymentWebhook(
            gateway: 'paystack',
            transactionId: transactionId,
            status: status,
            receiverId: data?['customer']?.toString(),
            metadata: {
              'amount': data?['amount']?.toString(),
              'currency': data?['currency']?.toString(),
              'reference': data?['reference']?.toString(),
            },
          );
        }
        break;

      case 'transaction.created':
      case 'transaction.updated':
        final String? transactionId = data?['id']?.toString();
        final String? status = data?['status']?.toString();
        if (transactionId != null && status != null) {
          await handlePaymentWebhook(
            gateway: 'paystack',
            transactionId: transactionId,
            status: status,
            reference: data?['reference']?.toString(),
            receiverId: data?['customer']?.toString(),
            metadata: {
              'amount': data?['amount']?.toString(),
              'currency': data?['currency']?.toString(),
            },
          );
        }
        break;

      case 'charge.success':
        debugPrint('Paystack charge success webhook received');
        break;

      case 'charge.failed':
        final String? transactionId = data?['id']?.toString();
        if (transactionId != null) {
          await handlePaymentWebhook(
            gateway: 'paystack',
            transactionId: transactionId,
            status: data?['status']?.toString() ?? 'FAILED',
          );
        }
        break;

      default:
        debugPrint('Paystack webhook event not handled: $eventType');
    }
  }

  /// Processes a Flutterwave webhook callback.
  static Future<void> handleFlutterwaveWebhook(
    Map<String, dynamic> payload,
  ) async {
    final String? eventType = payload['event_type']?.toString();
    final Map<String, dynamic>? data = payload['data'];

    debugPrint('Flutterwave webhook received: $eventType');

    switch (eventType) {
      case 'charge.success':
        final String? transactionId = data?['id']?.toString();
        final String? status = data?['status']?.toString();
        if (transactionId != null && status != null) {
          await handlePaymentWebhook(
            gateway: 'flutterwave',
            transactionId: transactionId,
            status: status,
            reference: data?['reference']?.toString(),
            receiverId: data?['customer']?['account_number']?.toString(),
            metadata: {
              'amount': data?['amount']?.toString(),
              'currency': data?['currency']?.toString(),
              'connection_id': data?['connection_id']?.toString(),
            },
          );
        }
        break;

      case 'charge.failed':
        final String? transactionId = data?['id']?.toString();
        if (transactionId != null) {
          await handlePaymentWebhook(
            gateway: 'flutterwave',
            transactionId: transactionId,
            status: data?['status']?.toString() ?? 'FAILED',
          );
        }
        break;

      case 'charge.expired':
        final String? transactionId = data?['id']?.toString();
        if (transactionId != null) {
          await handlePaymentWebhook(
            gateway: 'flutterwave',
            transactionId: transactionId,
            status: 'EXPIRED',
          );
        }
        break;

      case 'charge.pending':
        debugPrint('Flutterwave charge pending: ${data?['id']}');
        break;

      case 'refund.success':
        debugPrint('Flutterwave refund success: ${data?['id']}');
        break;

      case 'refund.failed':
        debugPrint('Flutterwave refund failed');
        break;

      default:
        debugPrint('Flutterwave webhook event not handled: $eventType');
    }
  }
}

/// Exception thrown when both primary and secondary payment gateways fail.
///
/// Extends [Error] so it isn't accidentally swallowed by a generic
/// `catch (e)` in the calling flow — callers that want to surface a
/// friendly message must catch it explicitly.
class GatewayError extends Error {
  /// Human-readable summary of the failure.
  final String message;

  /// The gateways that were attempted, in order.
  final List<String> gatewaysUsed;

  /// Per-gateway diagnostic detail.
  final Map<String, dynamic> details;

  GatewayError({
    required this.message,
    required this.gatewaysUsed,
    this.details = const {},
  });

  @override
  String toString() => 'GatewayError: $message';
}
