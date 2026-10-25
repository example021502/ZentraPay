import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Defines the interface for email-based authentication.
abstract interface class LoginWithEmail extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  LoginWithEmail(super.channelHandler);

  /// Sends a one-time authentication code to the provided email.
  ///
  /// Returns a `Result<void>` indicating success or failure.
  Future<Result<void>> sendCode(String email);

  /// Logs in the user using a verification code.
  ///
  /// Takes a required `code` and an optional `email` parameter.
  /// Returns a `Result<PrivyUser>` containing the authenticated user.
  Future<Result<PrivyUser>> loginWithCode({
    required String code,
    required String email,
  });

  /// Links an email address to the currently authenticated user's account.
  ///
  /// [code] The OTP code sent to the email address.
  /// [email] The email address to link.
  /// Returns a `Result<PrivyUser>` containing the updated user if successful.
  Future<Result<PrivyUser>> linkWithCode({
    required String code,
    required String email,
  });

  /// Updates the user's email using a verification code.
  ///
  /// Takes a required `code` and `email` parameter.
  /// Returns a `Result<void>` indicating success or failure.
  Future<Result<void>> updateWithCode({
    required String code,
    required String email,
  });

  /// Unlinks an email address from the currently authenticated user's account.
  ///
  /// [email] The email address to unlink from the user.
  /// Returns a `Result<PrivyUser>` containing the updated user if successful, or a failure with an error.
  Future<Result<PrivyUser>> unlink({
    required String email,
  });
}
