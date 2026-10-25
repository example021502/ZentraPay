import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/mfa/totp/privy_user_totp_mfa_verify.dart';

/// Implementation of [PrivyUserTotpMfaVerify] that communicates with the native platform.
class RealPrivyUserTotpMfaVerify implements PrivyUserTotpMfaVerify {
  final MethodChannelHandler _channelHandler;

  /// Constructor that initializes the method channel handler for communication.
  RealPrivyUserTotpMfaVerify(this._channelHandler);

  @override
  Future<Result<void>> submit(String code) async {
    if (code.isEmpty) {
      LoggerService.error("MFA TOTP verify failed: Code is empty.");
      return const Failure(PrivyException("Code is required"));
    }

    LoggerService.debug("Verifying MFA TOTP code.");

    try {
      final result = await _channelHandler.invokeMethod<bool>(
        'mfaTotpVerify',
        {'code': code},
      );

      if (result == true) {
        LoggerService.debug("MFA TOTP verification successful.");
        return const Success(null);
      } else {
        LoggerService.error("Failed to verify MFA TOTP code.");
        return const Failure(PrivyException("Failed to verify TOTP code"));
      }
    } catch (e) {
      LoggerService.error("Exception during MFA TOTP verification: $e");
      return Failure(e.convertToPrivyException("Failed to verify TOTP code"));
    }
  }
}
