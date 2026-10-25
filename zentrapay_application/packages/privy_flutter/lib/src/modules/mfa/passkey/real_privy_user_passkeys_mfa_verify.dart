import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/privy_user_passkeys_mfa_verify.dart';

/// Implementation of [PrivyUserPasskeysMfaVerify] that communicates with the native platform.
class RealPrivyUserPasskeysMfaVerify implements PrivyUserPasskeysMfaVerify {
  final MethodChannelHandler _channelHandler;

  /// Constructor that initializes the method channel handler for communication.
  RealPrivyUserPasskeysMfaVerify(this._channelHandler);

  @override
  Future<Result<void>> submit(String relyingParty) async {
    LoggerService.debug("Verifying MFA Passkey.");

    try {
      final result = await _channelHandler.invokeMethod<bool>(
        'mfaPasskeyVerify',
        {'relyingParty': relyingParty},
      );

      if (result == true) {
        LoggerService.debug("MFA Passkey verification successful.");
        return const Success(null);
      } else {
        LoggerService.error("Failed to verify MFA Passkey.");
        return const Failure(PrivyException("Failed to verify Passkey"));
      }
    } catch (e) {
      LoggerService.error("Exception during MFA Passkey verification: $e");
      return Failure(e.convertToPrivyException("Failed to verify Passkey"));
    }
  }
}
