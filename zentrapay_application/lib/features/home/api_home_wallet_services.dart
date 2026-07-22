import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

final dio = ApiClient().dio;

// CREATE A FIAT ACCOUNT ==================================
Future<Map<String, dynamic>?> createFiatAccount(
  Map<String, dynamic> formData,
) async {
  try {
    final response = await dio.post(
      '/api/accounts/newAccount/fiat',
      data: formData,
    );
    print("RESPONSE:: ${response.data}");
    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    print("ERROR:: ${e.response?.data['message']}");
    rethrow;
  }
}

// CREATE A CRYPTO ACCOUNT =========================
Future<Map<String, dynamic>?> createCryptoAccount(
  Map<String, dynamic> formData,
) async {
  try {
    final Response response = await dio.post(
      '/api/newAccount/crypto',
      data: formData,
    );
    print("RESPONSE:: ${response.data}");
    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    print("ERROR:: ${e.response?.data['message']}");
    rethrow;
  }
}

// get Fiat balances ==================================
Future<Map<String, dynamic>?> getAllBalances() async {
  try {
    final response = await dio.get('/api/accounts/balances/all');
    debugPrint('REGISTER RESPONSE: ${response.data}');
    if (response.data is Map) {
      return Map<String, dynamic>.from(response.data);
    }
  } on DioException catch (e) {
    print("ERROR:: ${e.response?.data['message']}");
    rethrow;
  }
}

// get Fiat balances ==================================
Future<Map<String, dynamic>?> getFiatBalances() async {
  try {
    final Response response = await dio.get(
      '/api/accounts/balances/fiatBalances',
    );
    print("FIAT BALANCES:: ${response.data}");
    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    print("ERROR:: ${e.response?.data['message']}");
    rethrow;
  }
}

// get crypto balances ==================================
Future<Map<String, dynamic>?> getCryptoBalances() async {
  try {
    final response = await dio.get('/api/accounts/balances/cryptoBalances');
    print("CRYPTO BALANCES:: ${response.data}");
    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    print("ERROR:: ${e.response?.data['message']}");
    rethrow;
  }
}

// getting recent outward payments =============================
Future<Map<String, dynamic>?> getRecentPaymentsBills() async {
  try {
    final Response response = await dio.get('/api/getRecentPaymentsBills');
    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    debugPrint("ERROR:: ${e.response?.data["message"]}");
    rethrow;
  }
}

// search contacts =============================
Future<Map<String, dynamic>> searchContacts(String query) async {
  try {
    final Response response = await dio.get(
      '/api/searchContacts',
      queryParameters: {"query": query},
    );
    print("Searched: $response");
    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    debugPrint("ERROR:: ${e.response?.data["message"]}");
    rethrow;
  }
}

// bill providers =============================
Future<Map<String, dynamic>> getBillProviders() async {
  try {
    final response = await dio.get('/api/billProviders');
    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    debugPrint("ERROR:: ${e.response?.data["message"]}");
    rethrow;
  }
}

// national transaction =============================
Future<Map<String, dynamic>?> makeTransfer(Map<String, dynamic> form) async {
  try {
    print("THE PAYMENT FORM:: $form");
    // Perform the API transaction request
    final response = await dio.post('/api/payments/initiate', data: form);
    // Comment: Returns the successful response back to the caller component
    return Map<String, dynamic>.from(response.data);
  } on DioException catch (e) {
    debugPrint("ERROR:: ${e.response?.data["message"]}");
    rethrow;
  }
}

// all history =============================
Future<Response<dynamic>?> getHistory() async {
  try {
    // Perform the API transaction request
    final response = await dio.get('/api/history');
    // Comment: Returns the successful response back to the caller component
    return response;
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      ZentraNotifier.error(
        "Authentication Error",
        "Something went wrong: ${e.response?.data["message"] ?? 'Unauthorized access'}",
      );
    }
    // Comment: Return the error response payload instead of throwing an app crash
    return e.response;
  } catch (e) {
    // Catch-all block for completely unexpected runtime errors (e.g., formatting issues)
    return null;
  }
}

// GET ACCESS CODE FROM FLUTTER FOR PAYMENT POPUP =============================
Future<Response<dynamic>?> getAccessCode(Map<String, dynamic> form) async {
  try {
    // Perform the API transaction request
    final response = await dio.get(
      '/api/paystackAccessCode/accessCode',
      queryParameters: form,
    );
    return response;
  } catch (e) {
    print("ERROR:: $e");
    // Catch-all block for completely unexpected runtime errors (e.g., formatting issues)
    return null;
  }
}
