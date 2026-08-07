import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/repositories/transactions_repository.dart';
import 'package:zentrapay_application/core/repositories/wallets_repository.dart';

/// Money-movement operations (internal transfer, bank disbursement, card
/// funding via Paystack). These aren't cached resources themselves — each
/// call is a deliberate user action — but every successful call updates the
/// two caches a payment affects (the sender's wallet balance and the
/// transaction history) instead of leaving other screens to refetch.
class PaymentsService {
  static final Dio _dio = ApiClient().dio;

  static Future<AppTransaction> payInternal({
    required String pin,
    String? recipientPhoneNumber,
    String? recipientZentag,
    required String amount,
    required String currencyCode,
  }) async {
    final response = await _dio.post(
      '/api/payments/internal',
      data: {
        'pin': pin,
        'recipient': {
          'phoneNumber': ?recipientPhoneNumber,
          'zentag': ?recipientZentag,
        },
        'amount': amount,
        'currencyCode': currencyCode,
      },
    );
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
        'description': ?description,
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

  static AppTransaction _applyTransactionResult(Map<String, dynamic> json) {
    final transaction = AppTransaction.fromJson(json);
    TransactionsRepository.instance.prepend(transaction);
    // The wallet's balance changed server-side; the cheapest correct move
    // is a forced refresh of the (already-loaded) wallets snapshot rather
    // than trying to recompute the new balance client-side.
    WalletsRepository.instance.ensureLoaded(forceRefresh: true);
    return transaction;
  }
}
