import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import 'package:zentrapay_application/core/utils/interceptor.dart';

/// External Payment Service
///
/// This service handles all external payment operations using Paystack.
/// External payments are transactions to bank accounts outside ZentraPay.
///
/// @description Integrates with Paystack API for processing external national transactions
/// @version 1.0.0
/// @author ZentraPay Team
class ExternalPaymentService {
  // Use the custom client wrapper instead of bare http/dio instances
  final Dio dio = ApiClient().dio;

  /// Initialize external payment
  /// @description Creates a payment intent with Paystack for external transfer
  /// @param {Map<String, dynamic>} paymentData - Payment details
  /// @returns {Future<Map<String, dynamic>>} Payment initialization response
  Future<Map<String, dynamic>?> initializeExternalPayment({
    required Map<String, dynamic> paymentData,
  }) async {
    try {
      print(paymentData);
      // Validate required fields locally before transmitting cargo
      if (paymentData['amount'] <= 0.00 ||
          paymentData['currency_code'] == "" ||
          paymentData['bank_name'] == "" ||
          paymentData['bank_code'] == "" ||
          paymentData['account_name'] == "" ||
          paymentData['account_number'] == "") {
        return {
          'success': false,
          'message': 'Missing required payment information',
        };
      }

      // No prefix tag here -> Interceptor maps this to your backend server architecture
      final Response response = await dio.post(
        'api/payment/bankTransfer',
        data: paymentData,
      );
      return Map<String, dynamic>.of(response.data);
    } on DioException catch (de) {
      print("DE ERROR: $de");
      return {
        'success': false,
        'message':
            de.response?.data?['message'] ?? 'Network exception occurred.',
      };
    } catch (e) {
      print("CATCH ERROR: $e");
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Verify external payment
  /// @description Checks the status of a payment with Paystack
  /// @param {String} reference - Transaction reference to verify
  /// @returns {Future<Map<String, dynamic>>} Verification response
  Future<Map<String, dynamic>> verifyExternalPayment(String reference) async {
    try {
      if (reference.isEmpty) {
        return {
          'success': false,
          'message': 'Transaction reference is required',
        };
      }

      // Dio gracefully maps the dynamic query parameters into structured formatting
      final response = await dio.get(
        '/api/payments/external/verify',
        queryParameters: {'reference': reference},
      );

      final responseData = response.data;

      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'status': responseData['status'],
          'message': responseData['message'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to verify payment',
        };
      }
    } on DioException catch (de) {
      return {
        'success': false,
        'message':
            de.response?.data?['message'] ?? 'Verification request failed.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get transaction status
  /// @description Retrieves the status of a specific transaction
  /// @param {String} reference - Transaction reference
  /// @returns {Future<Map<String, dynamic>>} Transaction status
  Future<Map<String, dynamic>> getTransactionStatus({
    required String reference,
  }) async {
    try {
      if (reference.isEmpty) {
        return {
          'success': false,
          'message': 'Transaction reference is required',
        };
      }

      final response = await dio.get(
        '/api/payments/external/status/$reference',
      );

      final responseData = response.data;

      if (response.statusCode == 200 && responseData['success'] == true) {
        debugPrint("THE BANKS ARE:: $responseData");
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to get transaction status',
        };
      }
    } on DioException catch (de) {
      return {
        'success': false,
        'message': de.response?.data?['message'] ?? 'Status request failed.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get supported banks
  /// @description Fetches list of banks supported by Paystack Network directly
  /// @returns {Future<Map<String, dynamic>>} List of supported banks
  Future<Map<String, dynamic>> getSupportedBanks() async {
    try {
      // CHANGED: Notice the '/paystack/' identifier prefix.
      // The interceptor routes this straight to Paystack instead of your backend servers!
      final response = await dio.get('/api/bankAccounts/paystack');
      print("RESPONSE FOR BANKS IS:: $response");

      final responseData = response.data;

      // Note: Paystack uses a root key named 'status' instead of your backend's 'success' wrapper
      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data']};
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to fetch banks from platform',
        };
      }
    } on DioException catch (de) {
      return {
        'success': false,
        'message':
            de.response?.data?['message'] ?? 'Platform connectivity error.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Validate bank account
  /// @description Real-time lookup resolving account identifiers directly against network endpoints
  /// @param {String} accountNumber - Bank account number
  /// @param {String} bankCode - Bank code
  /// @returns {Future<Map<String, dynamic>>} Validation result
  Future<Map<String, dynamic>> validateBankAccount({
    required String accountNumber,
    required String bankCode,
  }) async {
    try {
      if (accountNumber.isEmpty || bankCode.isEmpty) {
        return {
          'success': false,
          'message': 'Account number and bank code are required',
        };
      }

      // CHANGED: Now running live, secure verification using Paystack's endpoint via the interceptor path routing
      final response = await dio.get(
        '/paystack/bank/resolve',
        queryParameters: {
          'account_number': accountNumber,
          'bank_code': bankCode,
        },
      );

      final responseData = response.data;

      if (response.statusCode == 200 && responseData['status'] == true) {
        return {
          'success': true,
          'message': 'Account validation successful',
          'accountName': responseData['data']['account_name'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ??
              'Invalid account details matching configuration',
        };
      }
    } on DioException catch (de) {
      return {
        'success': false,
        'message':
            de.response?.data?['message'] ??
            'Account validation lookup failed.',
      };
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}
