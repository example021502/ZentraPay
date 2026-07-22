import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

// Access the configured dio instance
final dio = ApiClient().dio;

/// Fetches only the raw balance value as a String
Future<String> getBalance(String currency, String userId) async {
  try {
    // We tell Dio to expect a Map payload back from the server backend
    final response = await dio.get<Map<String, dynamic>>(
      '/api/getBalance',
      queryParameters: {"user_id": userId, "currencyCode": currency},
    );
    if (!response.data?["success"]) {
      ZentraNotifier.error(
        "Error",
        "Error occurred: ${response.data?["message"]}",
      );
    }
    final balance = response.data?['result'];

    // Convert it cleanly to a string and return it
    return balance?.toString() ?? "0.00";
  } on DioException catch (e) {
    // Process error messaging gracefully
    final errorMessage =
        e.response?.data?["message"] ?? "An unexpected error occurred.";
    final title = e.response?.statusCode == 401
        ? "Authentication Error"
        : "Unknown Error";

    ZentraNotifier.error(title, "Something went wrong: $errorMessage");

    rethrow;
  }
}
