import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/mfa/sms/privy_user_sms_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';

/// Implementation of [PrivyUserSmsMfaEnroll] that communicates with the native platform.
class RealPrivyUserSmsMfaEnroll implements PrivyUserSmsMfaEnroll {
  final MethodChannelHandler _channelHandler;

  /// Constructor that initializes the method channel handler for communication.
  RealPrivyUserSmsMfaEnroll(this._channelHandler);

  @override
  Future<Result<void>> sendCode(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      LoggerService.error("MFA SMS sendCode failed: Phone number is empty.");
      return const Failure(PrivyException("Phone number is required"));
    }

    LoggerService.debug(
        "Sending MFA SMS enrollment code to phone number: $phoneNumber");

    try {
      final result = await _channelHandler.invokeMethod<bool>(
        'mfaSmsSendCodeEnroll',
        {'phoneNumber': phoneNumber},
      );

      if (result == true) {
        LoggerService.debug(
            "MFA SMS enrollment code successfully sent to $phoneNumber.");
        return const Success(null);
      } else {
        LoggerService.error("Failed to send MFA SMS enrollment code.");
        return const Failure(PrivyException("Failed to send SMS code"));
      }
    } catch (e) {
      LoggerService.error(
          "Exception while sending MFA SMS enrollment code: $e");
      return Failure(e.convertToPrivyException("Failed to send SMS code"));
    }
  }

  @override
  Future<Result<PrivyUser>> submit({
    required String code,
    required String phoneNumber,
  }) async {
    if (code.isEmpty) {
      LoggerService.error("MFA SMS enroll failed: Code is empty.");
      return const Failure(PrivyException("Code is required"));
    }
    if (phoneNumber.isEmpty) {
      LoggerService.error("MFA SMS enroll failed: Phone number is empty.");
      return const Failure(PrivyException("Phone number is required"));
    }

    LoggerService.debug(
        "Completing MFA SMS enrollment for phone: $phoneNumber");

    try {
      final responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'mfaSmsEnroll',
        {'code': code, 'phoneNumber': phoneNumber},
      );

      if (responseData == null) {
        LoggerService.error("MFA SMS enrollment returned null response.");
        return const Failure(PrivyException("Failed to enroll SMS MFA"));
      }

      final user = RealPrivyUser.fromJson(safeCastToMap(responseData));
      LoggerService.debug("MFA SMS enrollment successful. User ID: ${user.id}");
      return Success(user);
    } catch (e) {
      LoggerService.error("Exception during MFA SMS enrollment: $e");
      return Failure(e.convertToPrivyException("Failed to enroll SMS MFA"));
    }
  }
}
