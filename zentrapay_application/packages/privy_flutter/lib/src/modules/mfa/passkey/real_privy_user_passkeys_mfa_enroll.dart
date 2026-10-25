import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/privy_user_passkeys_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';

/// Implementation of [PrivyUserPasskeysMfaEnroll] that communicates with the native platform.
class RealPrivyUserPasskeysMfaEnroll implements PrivyUserPasskeysMfaEnroll {
  final MethodChannelHandler _channelHandler;

  /// Constructor that initializes the method channel handler for communication.
  RealPrivyUserPasskeysMfaEnroll(this._channelHandler);

  @override
  Future<Result<PrivyUser>> submit(List<String> credentialIds) async {
    if (credentialIds.isEmpty) {
      LoggerService.error(
          "MFA Passkey enroll failed: Credential IDs is empty.");
      return const Failure(PrivyException("Credential IDs are required"));
    }

    LoggerService.debug("Completing MFA Passkey enrollment.");

    try {
      final responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'mfaPasskeyEnroll',
        {'credentialIds': credentialIds},
      );

      if (responseData == null) {
        LoggerService.error("MFA Passkey enrollment returned null response.");
        return const Failure(PrivyException("Failed to enroll Passkey MFA"));
      }

      final user = RealPrivyUser.fromJson(safeCastToMap(responseData));
      LoggerService.debug(
          "MFA Passkey enrollment successful. User ID: ${user.id}");
      return Success(user);
    } catch (e) {
      LoggerService.error("Exception during MFA Passkey enrollment: $e");
      return Failure(e.convertToPrivyException("Failed to enroll Passkey MFA"));
    }
  }
}
