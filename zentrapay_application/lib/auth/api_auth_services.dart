import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:privy_flutter/privy_flutter.dart'; // Import Privy SDK
import 'package:zentrapay_application/Notifier.dart';
import 'package:zentrapay_application/interceptor.dart';

final dio = ApiClient().dio;

// Keep track of the active token in memory so Privy can fetch it on demand
String? _currentCustomToken;

// Initialize your Privy instance with the custom authentication configuration provider
final Privy privy = Privy.init(
  config: PrivyConfig(
    appId: 'your_privy_app_id_here', // From Privy Settings > Basics
    appClientId: 'your_app_client_id_here', // From Privy Settings > Clients
    customAuthConfig: LoginWithCustomAuthConfig(
      tokenProvider: () async => _currentCustomToken,
    ),
  ),
);

// Logging in
Future<Response<dynamic>> loginUser(Map<String, String> form) async {
  try {
    final response = await dio.post('/api/login', data: form);

    // Extract the custom token sent by your Node.js backend
    final String? appCustomToken = response.data['token'];

    if (appCustomToken != null) {
      // 1. Update the local state provider before telling Privy to authenticate
      _currentCustomToken = appCustomToken;

      // 2. Call the method with zero arguments as expected
      final Result<PrivyUser> loginResult = await privy.customAuth
          .loginWithCustomAccessToken();

      // 3. Unbox the Result correctly using the updated Failure matching rule
      switch (loginResult) {
        case Success(value: final user):
          debugPrint("Privy initialized seamlessly! User DID: ${user.id}");

          // Silently spin up an embedded wallet if this user doesn't have one yet
          if (user.embeddedEthereumWallets.isEmpty) {
            debugPrint("Creating new embedded Ethereum wallet silently...");
            await user.createEthereumWallet();
          }
          break;

        case Failure(
          error: final err,
        ): // Fixed: changed 'exception' parameter mapping to 'error'
          debugPrint("Privy Custom Auth Verification Failed: ${err.message}");
          ZentraNotifier.error(
            "Wallet Initialization Error",
            "Could not initialize Web3 session: ${err.message}",
          );
          break;
      }
    }

    return response;
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      ZentraNotifier.error(
        "Authentication Error",
        "Something went wrong: ${e.response?.data["message"]}",
      );
    } else {
      ZentraNotifier.error(
        "Unknown Error",
        "Something went wrong: ${e.response?.data["message"]}",
      );
    }
    rethrow;
  }
}

// Registering new user
Future<Response<dynamic>> registerUser(Map<String, String> form) async {
  try {
    final response = await dio.post('/api/register', data: form);

    final String? appCustomToken = response.data['token'];

    if (appCustomToken != null) {
      _currentCustomToken = appCustomToken;

      final Result<PrivyUser> registrationResult = await privy.customAuth
          .loginWithCustomAccessToken();

      switch (registrationResult) {
        case Success(value: final user):
          debugPrint(
            "Privy auto-initialized after registration! User DID: ${user.id}",
          );
          if (user.embeddedEthereumWallets.isEmpty) {
            await user.createEthereumWallet();
          }
          break;

        case Failure(error: final err):
          debugPrint(
            "Privy auto-auth after registration failed: ${err.message}",
          );
          break;
      }
    }

    return response;
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      ZentraNotifier.error(
        "Authentication Error",
        "Something went wrong: ${e.response?.data["message"]}",
      );
    } else {
      ZentraNotifier.error(
        "Unknown Error",
        "Something went wrong: ${e.response?.data["message"]}",
      );
    }
    rethrow;
  }
}
