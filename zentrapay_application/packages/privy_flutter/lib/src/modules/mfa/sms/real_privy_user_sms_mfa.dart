import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/mfa/sms/privy_user_sms_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/sms/privy_user_sms_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/mfa/sms/privy_user_sms_mfa_verify.dart';
import 'package:privy_flutter/src/modules/mfa/sms/real_privy_user_sms_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/mfa/sms/real_privy_user_sms_mfa_verify.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';

/// Implementation of [PrivyUserSmsMfa] that communicates with the native platform.
class RealPrivyUserSmsMfa implements PrivyUserSmsMfa {
  final MethodChannelHandler _channelHandler;

  @override
  final PrivyUserSmsMfaEnroll enroll;

  @override
  final PrivyUserSmsMfaVerify verify;

  /// Constructor that initializes all sub-modules.
  RealPrivyUserSmsMfa(this._channelHandler)
      : enroll = RealPrivyUserSmsMfaEnroll(_channelHandler),
        verify = RealPrivyUserSmsMfaVerify(_channelHandler);

  @override
  Future<Result<PrivyUser>> unenroll() async {
    LoggerService.debug("Unenrolling SMS MFA.");

    try {
      final responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'mfaSmsUnenroll',
      );

      if (responseData == null) {
        LoggerService.error("MFA SMS unenroll returned null response.");
        return const Failure(PrivyException("Failed to unenroll SMS MFA"));
      }

      final user = RealPrivyUser.fromJson(safeCastToMap(responseData));
      LoggerService.debug("MFA SMS unenroll successful. User ID: ${user.id}");
      return Success(user);
    } catch (e) {
      LoggerService.error("Exception during MFA SMS unenroll: $e");
      return Failure(e.convertToPrivyException("Failed to unenroll SMS MFA"));
    }
  }
}
