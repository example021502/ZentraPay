import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/auth/auth_manager.dart';
import 'package:privy_flutter/src/modules/auth/link_type.dart';
import 'package:privy_flutter/src/modules/auth/unlink_type.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/sms/login_with_sms.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Implementation of `LoginWithSms` that communicates with the native platform.
class RealLoginWithSms implements LoginWithSms {
  final MethodChannelHandler _channelHandler;
  final AuthManager _authManager;

  /// Initializes with a method channel handler for Flutter-native communication.
  RealLoginWithSms(this._channelHandler, this._authManager);

  /// Sends an OTP via SMS to the given phone number.
  ///
  /// Returns a `Result<void>` indicating success or failure.
  @override
  Future<Result<void>> sendCode(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      LoggerService.error("sendCode failed: Phone number is empty.");
      return const Failure(PrivyException("Phone number is required"));
    }

    LoggerService.debug("Sending SMS code to phone number: $phoneNumber");

    try {
      // Calls the native platform method to send an OTP.
      final result = await _channelHandler.invokeMethod<bool>(
        'smsSendCode',
        {'phoneNumber': phoneNumber}, // Send phone number as a map
      );

      // Returns success if the OTP was sent successfully.
      if (result == true) {
        LoggerService.debug("SMS code successfully sent to $phoneNumber.");
        return const Success(null);
      } else {
        LoggerService.error("Failed to send SMS code.");
        return const Failure(PrivyException("Failed to send code"));
      }
    } catch (e) {
      LoggerService.error("Exception while sending SMS code: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// Logs in a user using an OTP code sent to their phone number.
  ///
  /// Returns a `Result<PrivyUser>` representing the success or failure of the login.
  @override
  Future<Result<PrivyUser>> loginWithCode(
      {required String code, String? phoneNumber}) async {
    if (code.isEmpty) {
      LoggerService.error("loginWithCode failed: OTP code is empty.");
      return const Failure(PrivyException("OTP code is required"));
    }

    LoggerService.debug(
        "Attempting SMS login with code: $code for phone: $phoneNumber");

    try {
      // Calls the native platform method to verify OTP and log in.
      final Map<Object?, Object?>? responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'smsLoginWithCode',
        {
          'phoneNumber': phoneNumber,
          'code': code,
        },
      );

      final convertedUser = safeCastToMap(responseData);

      // Convert response data into a `PrivyUser` instance.
      final user = RealPrivyUser.fromJson(convertedUser);

      LoggerService.debug("User successfully logged in. User ID: ${user.id}");
      return Success(user);
    } catch (e) {
      LoggerService.error("Exception during SMS login: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  @override
  Future<Result<PrivyUser>> linkWithCode(
      {required String code, required String phoneNumber}) async {
    LoggerService.debug(
        "Attempting to link phone number with OTP. Phone: $phoneNumber, Code: $code");
    return _authManager.link(SmsLink(phoneNumber: phoneNumber, code: code));
  }

  @override
  Future<Result<void>> updateWithCode(
      {required String code, required String phoneNumber}) async {
    LoggerService.debug(
        "Attempting to update phone number with OTP. Phone: $phoneNumber, Code: $code");

    try {
      // Don't specify the return type - let it be inferred since the native code returns a boolean
      await _channelHandler.invokeMethod(
        'smsUpdateWithCode',
        {
          'phoneNumber': phoneNumber,
          'code': code,
        },
      );

      // Refresh the user to ensure we have the latest data after updating
      final refreshResult = await _authManager.refreshUser();
      if (refreshResult is Failure) {
        LoggerService.warning(
            "Phone number updated successfully but failed to refresh user data: ${refreshResult.error}");
      }

      LoggerService.debug("Successfully updated phone number: $phoneNumber");
      return const Success(null);
    } catch (e) {
      LoggerService.error("updateWithCode failed with exception: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  @override
  Future<Result<PrivyUser>> unlink({
    required String phoneNumber,
  }) async {
    LoggerService.debug("Attempting to unlink phone number: $phoneNumber");

    return _authManager.unlink(SmsUnlink(phoneNumber: phoneNumber));
  }
}
