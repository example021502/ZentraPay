import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/mfa/totp/privy_user_totp_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/totp/privy_user_totp_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/mfa/totp/privy_user_totp_mfa_verify.dart';
import 'package:privy_flutter/src/modules/mfa/totp/real_privy_user_totp_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/mfa/totp/real_privy_user_totp_mfa_verify.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';

/// Implementation of [PrivyUserTotpMfa] that communicates with the native platform.
class RealPrivyUserTotpMfa implements PrivyUserTotpMfa {
  final MethodChannelHandler _channelHandler;

  @override
  final PrivyUserTotpMfaEnroll enroll;

  @override
  final PrivyUserTotpMfaVerify verify;

  /// Constructor that initializes all sub-modules.
  RealPrivyUserTotpMfa(this._channelHandler)
      : enroll = RealPrivyUserTotpMfaEnroll(_channelHandler),
        verify = RealPrivyUserTotpMfaVerify(_channelHandler);

  @override
  Future<Result<PrivyUser>> unenroll() async {
    LoggerService.debug("Unenrolling TOTP MFA.");

    try {
      final responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'mfaTotpUnenroll',
      );

      if (responseData == null) {
        LoggerService.error("MFA TOTP unenroll returned null response.");
        return const Failure(PrivyException("Failed to unenroll TOTP MFA"));
      }

      final user = RealPrivyUser.fromJson(safeCastToMap(responseData));
      LoggerService.debug("MFA TOTP unenroll successful. User ID: ${user.id}");
      return Success(user);
    } catch (e) {
      LoggerService.error("Exception during MFA TOTP unenroll: $e");
      return Failure(e.convertToPrivyException("Failed to unenroll TOTP MFA"));
    }
  }
}
