import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/mfa/totp/privy_user_totp_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/mfa/totp/totp_secret.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';

/// Implementation of [PrivyUserTotpMfaEnroll] that communicates with the native platform.
class RealPrivyUserTotpMfaEnroll implements PrivyUserTotpMfaEnroll {
  final MethodChannelHandler _channelHandler;

  /// Constructor that initializes the method channel handler for communication.
  RealPrivyUserTotpMfaEnroll(this._channelHandler);

  @override
  Future<Result<TotpSecret>> generateSecret() async {
    LoggerService.debug("Generating TOTP secret for enrollment.");

    try {
      final responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'mfaTotpGenerateSecret',
      );

      if (responseData == null) {
        LoggerService.error("TOTP generateSecret returned null response.");
        return const Failure(PrivyException("Failed to generate TOTP secret"));
      }

      final secret = TotpSecret.fromJson(safeCastToMap(responseData));
      LoggerService.debug("TOTP secret generated successfully.");
      return Success(secret);
    } catch (e) {
      LoggerService.error("Exception while generating TOTP secret: $e");
      return Failure(
          e.convertToPrivyException("Failed to generate TOTP secret"));
    }
  }

  @override
  Future<Result<PrivyUser>> submit(String code) async {
    if (code.isEmpty) {
      LoggerService.error("MFA TOTP enroll failed: Code is empty.");
      return const Failure(PrivyException("Code is required"));
    }

    LoggerService.debug("Completing MFA TOTP enrollment.");

    try {
      final responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'mfaTotpEnroll',
        {'code': code},
      );

      if (responseData == null) {
        LoggerService.error("MFA TOTP enrollment returned null response.");
        return const Failure(PrivyException("Failed to enroll TOTP MFA"));
      }

      final user = RealPrivyUser.fromJson(safeCastToMap(responseData));
      LoggerService.debug(
          "MFA TOTP enrollment successful. User ID: ${user.id}");
      return Success(user);
    } catch (e) {
      LoggerService.error("Exception during MFA TOTP enrollment: $e");
      return Failure(e.convertToPrivyException("Failed to enroll TOTP MFA"));
    }
  }
}
