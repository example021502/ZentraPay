import 'paystack_platform_interface.dart';
import 'models.dart';

/// The base class for managing payments within your app
class Paystack {
  /// Configure payment using with:
  /// publickKey - gotten from the Paystack dashboard
  /// enableLogging - toggle if you need to view logs or not
  Future<bool> initialize(String publicKey, bool enableLogging) {
    return PaystackSDKPlatform.instance.initialize(publicKey, enableLogging);
  }

  /// This method launches the payment UI for customers to interact with
  /// when completing a payment
  Future<TransactionResponse> launch(String accessCode) {
    return PaystackSDKPlatform.instance.launch(accessCode);
  }
}
