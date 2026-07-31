import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

final dio = ApiClient().dio;

Future<Response<dynamic>> Authentication(String pin) async {
  try {
    final response = await dio.post(
      '/api/users/pin/verify',
      data: {"pin": pin},
    );
    return response;
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      ZentraNotifier.error(
        "Authentication Error",
        "Something went wrong: ${e.response?.data["message"]}",
      );
    } else {
      debugPrint("Error: $e");
    }
    rethrow;
  }
}
