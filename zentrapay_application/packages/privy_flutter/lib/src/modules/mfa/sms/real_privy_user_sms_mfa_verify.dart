import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/mfa/sms/privy_user_sms_mfa_verify.dart';

/// Implementation of [PrivyUserSmsMfaVerify] that communicates with the native platform.
class RealPrivyUserSmsMfaVerify implements PrivyUserSmsMfaVerify {
  final MethodChannelHandler _channelHandler;

  /// Constructor that initializes the method channel handler for communication.
  RealPrivyUserSmsMfaVerify(this._channelHandler);

  @override
  Future<Result<void>> sendCode() async {
    LoggerService.debug("Sending MFA SMS verification code.");

    try {
      final result = await _channelHandler.invokeMethod<bool>(
        'mfaSmsSendCodeVerify',
      );

      if (result == true) {
        LoggerService.debug("MFA SMS verification code successfully sent.");
        return const Success(null);
      } else {
        LoggerService.error("Failed to send MFA SMS verification code.");
        return const Failure(
            PrivyException("Failed to send SMS verification code"));
      }
    } catch (e) {
      LoggerService.error(
          "Exception while sending MFA SMS verification code: $e");
      return Failure(
          e.convertToPrivyException("Failed to send SMS verification code"));
    }
  }

  @override
  Future<Result<void>> submit(String code) async {
    if (code.isEmpty) {
      LoggerService.error("MFA SMS verify failed: Code is empty.");
      return const Failure(PrivyException("Code is required"));
    }

    LoggerService.debug("Verifying MFA SMS code.");

    try {
      final result = await _channelHandler.invokeMethod<bool>(
        'mfaSmsVerify',
        {'code': code},
      );

      if (result == true) {
        LoggerService.debug("MFA SMS verification successful.");
        return const Success(null);
      } else {
        LoggerService.error("Failed to verify MFA SMS code.");
        return const Failure(PrivyException("Failed to verify SMS code"));
      }
    } catch (e) {
      LoggerService.error("Exception during MFA SMS verification: $e");
      return Failure(e.convertToPrivyException("Failed to verify SMS code"));
    }
  }
}
