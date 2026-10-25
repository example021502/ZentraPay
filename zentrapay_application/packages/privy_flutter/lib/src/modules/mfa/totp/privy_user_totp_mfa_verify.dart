import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// TOTP MFA verification operations.
///
/// Access via `user.mfa.totp.verify`.
///
/// Use these methods when the SDK triggers [MfaListener.onMfaRequired] and
/// the user chooses to verify via TOTP.
abstract interface class PrivyUserTotpMfaVerify extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  PrivyUserTotpMfaVerify(super.channelHandler);

  /// Verify TOTP MFA with a [code] from the authenticator app.
  ///
  /// After successful verification, call [PrivyMfa.resumeBlockedActions] to
  /// unblock any pending operations.
  Future<Result<void>> submit(String code);
}
