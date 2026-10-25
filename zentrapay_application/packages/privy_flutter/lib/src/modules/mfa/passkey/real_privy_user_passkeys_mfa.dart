import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/privy_user_passkeys_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/privy_user_passkeys_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/privy_user_passkeys_mfa_verify.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/real_privy_user_passkeys_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/real_privy_user_passkeys_mfa_verify.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';

/// Implementation of [PrivyUserPasskeysMfa] that communicates with the native platform.
class RealPrivyUserPasskeysMfa implements PrivyUserPasskeysMfa {
  final MethodChannelHandler _channelHandler;

  @override
  final PrivyUserPasskeysMfaEnroll enroll;

  @override
  final PrivyUserPasskeysMfaVerify verify;

  /// Constructor that initializes all sub-modules.
  RealPrivyUserPasskeysMfa(this._channelHandler)
      : enroll = RealPrivyUserPasskeysMfaEnroll(_channelHandler),
        verify = RealPrivyUserPasskeysMfaVerify(_channelHandler);

  @override
  Future<Result<PrivyUser>> unenroll({bool removeForLogin = true}) async {
    LoggerService.debug("Unenrolling Passkey MFA.");

    try {
      final responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'mfaPasskeyUnenroll',
        {'removeForLogin': removeForLogin},
      );

      if (responseData == null) {
        LoggerService.error("MFA Passkey unenroll returned null response.");
        return const Failure(PrivyException("Failed to unenroll Passkey MFA"));
      }

      final user = RealPrivyUser.fromJson(safeCastToMap(responseData));
      LoggerService.debug(
          "MFA Passkey unenroll successful. User ID: ${user.id}");
      return Success(user);
    } catch (e) {
      LoggerService.error("Exception during MFA Passkey unenroll: $e");
      return Failure(
          e.convertToPrivyException("Failed to unenroll Passkey MFA"));
    }
  }
}
