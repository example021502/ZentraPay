import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Interface for handling SMS authentication.
abstract interface class LoginWithSms extends PrivyPluginModule {
  /// Initializes the module with a channel handler.
  LoginWithSms(super.channelHandler);

  /// Sends an OTP via SMS to the given phone number (E.164 format).
  /// Returns a `Result<void>` indicating success or failure.
  Future<Result<void>> sendCode(String phoneNumber);

  /// Logs in a user using an OTP code sent to their phone number.
  Future<Result<PrivyUser>> loginWithCode(
      {required String code, String? phoneNumber});

  Future<Result<PrivyUser>> linkWithCode({
    required String code,
    required String phoneNumber,
  });

  /// Updates the user's phone number using a verification code.
  ///
  /// Takes a required `code` and `phoneNumber` parameter.
  /// Returns a `Result<void>` indicating success or failure.
  Future<Result<void>> updateWithCode({
    required String code,
    required String phoneNumber,
  });

  /// Unlinks a phone number from the currently authenticated user's account.
  ///
  /// [phoneNumber] The phone number to unlink from the user.
  /// Returns a `Result<PrivyUser>` containing the updated user if successful, or a failure with an error.
  Future<Result<PrivyUser>> unlink({
    required String phoneNumber,
  });
}
