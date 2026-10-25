import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Passkey MFA verification operations.
///
/// Access via `user.mfa.passkeys.verify`.
///
/// Use these methods when the SDK triggers [MfaListener.onMfaRequired] and
/// the user chooses to verify via Passkey.
abstract interface class PrivyUserPasskeysMfaVerify extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  PrivyUserPasskeysMfaVerify(super.channelHandler);

  /// Verify Passkey MFA (triggers biometric prompt).
  ///
  /// This will prompt the user to authenticate using their device's
  /// biometric authentication (Face ID, Touch ID, fingerprint, etc.).
  ///
  /// [relyingParty] is the relying party identifier (typically your domain).
  ///
  /// After successful verification, call [PrivyMfa.resumeBlockedActions] to
  /// unblock any pending operations.
  Future<Result<void>> submit(String relyingParty);
}
