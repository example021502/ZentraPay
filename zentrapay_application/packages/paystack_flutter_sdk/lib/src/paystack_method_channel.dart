import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'paystack_platform_interface.dart';
import 'models.dart';

/// This class serves as the bridge between Flutter and native code
class MethodChannelPaystackSDK extends PaystackSDKPlatform {
  /// Sets the unique identifier of the bridge
  @visibleForTesting
  final methodChannel = const MethodChannel('com.paystack.flutter');

  @override
  Future<bool> initialize(String publicKey, bool enableLogging) async {
    try {
      final response = await methodChannel.invokeMethod<bool>('initialize',
          {'publicKey': publicKey, 'enableLogging': enableLogging});

      return response!;
    } on PlatformException catch (e) {
      throw PaystackException(
          message: e.message!, code: e.code, details: e.details);
    }
  }

  @override
  Future<TransactionResponse> launch(String accessCode) async {
    try {
      final response = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
          'launch', {'accessCode': accessCode});

      return TransactionResponse.fromMap(response as Map<dynamic, dynamic>);
    } on PlatformException catch (e) {
      throw PaystackException(
          message: e.message!, code: e.code, details: e.details);
    }
  }
}
