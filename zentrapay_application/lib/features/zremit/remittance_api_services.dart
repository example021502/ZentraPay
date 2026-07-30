import '../../core/utils/interceptor.dart';

final dio = ApiClient().dio;

Future<Map<String, dynamic>> submitRemittanceTransfer({
  required Map<String, dynamic> currencyDetails,
  required Map<String, dynamic> recipientDetails,
  required String payoutType,
  required Map<String, dynamic> bankDetails,
  required Map<String, dynamic> mobileMoneyDetails,
  required String transactionPin,
}) async {
  // Construct the structured JSON payload matching the backend schema
  final Map<String, dynamic> requestPayload = {
    "sourceTransaction": currencyDetails,
    "recipientDetails": recipientDetails,
    "payoutMethod": payoutType,
    "destinationDetails": payoutType == 'bank'
        ? bankDetails
        : mobileMoneyDetails,
    "transactionPin": transactionPin,
  };
  print("THE PAYLOAD IS::$requestPayload");
  return {};

  // try {
  //   final response = await dio.post(
  //     '/api/remittance/transfer',
  //     data: requestPayload,
  //   );
  //
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     // Successfully initiated, return parsed response data (e.g. transaction ID, status: Pending)
  //     return response.data;
  //   } else {
  //     // Handle server errors or validation rejections
  //     throw Exception("Failed to process transfer: ${response.data}");
  //   }
  // } on DioException catch (e) {
  //   // Handle Dio-specific errors
  //   final errorMessage =
  //       e.response?.data?['message'] ?? e.message ?? "Network error occurred";
  //   throw Exception(errorMessage);
  // } catch (e) {
  //   // Handle other exceptions
  //   throw Exception("Network error occurred: $e");
  // }
}
