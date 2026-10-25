import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'paystack_method_channel.dart';
import 'models.dart';

/// Interface set up and method definitions to be implemented by
/// a concrete class
abstract class PaystackSDKPlatform extends PlatformInterface {
  /// Default constructor set up from the parent interface
  PaystackSDKPlatform() : super(token: _token);

  static final Object _token = Object();
  static PaystackSDKPlatform _instance = MethodChannelPaystackSDK();

  /// Getter for the interactions between the platform and bridge
  static PaystackSDKPlatform get instance => _instance;

  static set instance(PaystackSDKPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Method defintion for managing payment configuration
  Future<bool> initialize(String publicKey, bool enableLogging) {
    throw UnimplementedError('build() has not been implemented');
  }

  /// Method defintion for launching payment UI
  Future<TransactionResponse> launch(String accessCode) {
    throw UnimplementedError('launch() has not been implemented');
  }
}
