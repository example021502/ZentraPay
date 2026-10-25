import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Defines the interface for passkey-based authentication using FIDO2/WebAuthn.
///
/// Passkeys provide passwordless authentication using biometric or device credentials.
abstract interface class LoginWithPasskey extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  LoginWithPasskey(super.channelHandler);

  /// Signs up a new user with a passkey.
  ///
  /// This initiates the passkey creation flow:
  /// 1. Requests registration challenge from server
  /// 2. Prompts user to create passkey using biometrics/PIN
  /// 3. Registers the credential with server
  /// 4. Returns authenticated user
  ///
  /// [relyingParty] The domain that will own this credential (e.g., "yourdomain.com").
  /// Must match your Digital Asset Links configuration.
  ///
  /// [displayName] Optional user-friendly name shown in passkey selector.
  /// If not provided, defaults to a generic name.
  ///
  /// Returns a `Result<PrivyUser>` containing the authenticated user on success,
  /// or a PrivyException on failure.
  Future<Result<PrivyUser>> signup({
    required String relyingParty,
    String? displayName,
  });

  /// Logs in an existing user with their passkey.
  ///
  /// This initiates the passkey authentication flow:
  /// 1. Requests authentication challenge from server
  /// 2. Shows passkey selector to user
  /// 3. User authenticates using biometrics/PIN
  /// 4. Verifies credential with server
  /// 5. Returns authenticated user
  ///
  /// [relyingParty] The domain that owns the credential (e.g., "yourdomain.com").
  /// Must match your Digital Asset Links configuration.
  ///
  /// Returns a `Result<PrivyUser>` containing the authenticated user on success,
  /// or a PrivyException on failure.
  Future<Result<PrivyUser>> login({
    required String relyingParty,
  });

  /// Links a passkey to the currently authenticated user's account.
  ///
  /// This allows users to add passkey authentication to their existing account:
  /// 1. Verifies user is authenticated
  /// 2. Requests link challenge from server
  /// 3. Prompts user to create passkey using biometrics/PIN
  /// 4. Links the credential to the user's account
  ///
  /// [relyingParty] The domain that will own this credential (e.g., "yourdomain.com").
  /// Must match your Digital Asset Links configuration.
  ///
  /// [displayName] Optional user-friendly name shown in passkey selector.
  /// If not provided, defaults to a generic name.
  ///
  /// Returns a `Result<PrivyUser>` containing the updated user if successful, or a failure with an error.
  Future<Result<PrivyUser>> link({
    required String relyingParty,
    String? displayName,
  });

  /// Unlinks a passkey from the currently authenticated user's account.
  ///
  /// This removes a previously linked passkey credential:
  /// 1. Verifies user is authenticated
  /// 2. Requests unlink from server with credential ID
  /// 3. Removes the credential from the user's account
  ///
  /// [credentialId] The credential ID of the passkey to unlink.
  ///
  /// Returns a `Result<PrivyUser>` containing the updated user if successful, or a failure with an error.
  Future<Result<PrivyUser>> unlink({
    required String credentialId,
  });
}
