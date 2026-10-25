import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/auth/auth_manager.dart';
import 'package:privy_flutter/src/modules/auth/link_type.dart';
import 'package:privy_flutter/src/modules/auth/unlink_type.dart';
import 'package:privy_flutter/src/modules/email/login_with_email.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Implementation of the `LoginWithEmail` interface that interacts with the
/// native platform using method channels.
class RealLoginWithEmail implements LoginWithEmail {
  final MethodChannelHandler _channelHandler;
  final AuthManager _authManager;

  /// Constructor that initializes the method channel handler for communication.
  RealLoginWithEmail(this._channelHandler, this._authManager);

  /// Sends a one-time password (OTP) to the user's email address.
  ///
  /// Returns a `Result<bool>` indicating success or failure.
  @override
  Future<Result<void>> sendCode(String email) async {
    LoggerService.debug("Sending OTP to email: $email");

    if (email.isEmpty) {
      LoggerService.error("sendCode failed: Email is empty.");
      return const Failure(PrivyException("Email is required"));
    }

    try {
      final result = await _channelHandler.invokeMethod<bool>(
        'emailSendCode',
        {'email': email}, // Send email as a map
      );

      if (result == true) {
        LoggerService.debug("OTP successfully sent to email: $email");
        return const Success(null);
      } else {
        LoggerService.error("Failed to send OTP to email: $email");
        return const Failure(PrivyException("Failed to send code"));
      }
    } catch (e) {
      LoggerService.error("sendCode failed with exception: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// Logs in a user using an OTP code sent to their email.
  ///
  /// Returns a `Result<PrivyUser>` representing the success or failure of the login.
  @override
  Future<Result<PrivyUser>> loginWithCode(
      {required String code, required String email}) async {
    LoggerService.debug(
        "Attempting login with OTP. Email: $email, Code: $code");

    if (code.isEmpty) {
      LoggerService.error("loginWithCode failed: OTP code is empty.");
      return const Failure(PrivyException("OTP code is required"));
    }

    try {
      LoggerService.debug("Invoking method channel for emailLoginWithCode.");
      final Map<Object?, Object?>? responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'emailLoginWithCode',
        {
          'email': email,
          'code': code,
        },
      );

      LoggerService.debug(
          "Received response from emailLoginWithCode: $responseData");
      // Convert response data into a `PrivyUser` instance.
      final convertedUser = safeCastToMap(responseData);

      LoggerService.debug(
          "Successfully logged in user. User data: $convertedUser");
      return Success(RealPrivyUser.fromJson(convertedUser));
    } catch (e) {
      LoggerService.error("loginWithCode failed with exception: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  @override
  Future<Result<PrivyUser>> linkWithCode(
      {required String code, required String email}) async {
    LoggerService.debug(
        "Attempting to link email with OTP. Email: $email, Code: $code");
    return _authManager.link(EmailLink(email: email, code: code));
  }

  @override
  Future<Result<void>> updateWithCode(
      {required String code, required String email}) async {
    LoggerService.debug(
        "Attempting to update email with OTP. Email: $email, Code: $code");

    try {
      // Don't specify the return type - let it be inferred since the native code returns a boolean
      await _channelHandler.invokeMethod(
        'emailUpdateWithCode',
        {
          'email': email,
          'code': code,
        },
      );

      // Refresh the user to ensure we have the latest data after updating
      final refreshResult = await _authManager.refreshUser();
      if (refreshResult is Failure) {
        LoggerService.warning(
            "Email updated successfully but failed to refresh user data: ${refreshResult.error}");
      }

      LoggerService.debug("Successfully updated email: $email");
      return const Success(null);
    } catch (e) {
      LoggerService.error("updateWithCode failed with exception: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  @override
  Future<Result<PrivyUser>> unlink({
    required String email,
  }) async {
    LoggerService.debug("Attempting to unlink email: $email");

    return _authManager.unlink(EmailUnlink(email: email));
  }
}
