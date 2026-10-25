import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/modules/mfa/mfa_config.dart';

/// Entry point for MFA operations at the Privy level.
///
/// Access this via `privy.mfa` to manage blocked MFA operations.
abstract interface class PrivyMfa extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  PrivyMfa(super._channelHandler);

  /// Sets the MFA configuration for handling MFA prompts.
  ///
  /// Use this to configure a listener that will be called when operations require
  /// MFA verification, and to set the timeout for MFA verification.
  ///
  /// This configuration takes precedence over any [MfaConfig] provided
  /// in the initial `PrivyConfig`.
  Future<Result<void>> setConfig(MfaConfig config);

  /// Resumes any operations that were blocked waiting for MFA verification.
  ///
  /// Call this method after successfully verifying MFA (via `user.mfa.totp.verify.submit`,
  /// `user.mfa.sms.verify.submit`, or `user.mfa.passkeys.verify.submit`) to unblock
  /// pending wallet operations.
  ///
  /// This method MUST also be called when the user cancels MFA or verification fails,
  /// to unblock operations and allow them to fail gracefully.
  ///
  /// If this method is not called, blocked operations will eventually time out.
  ///
  /// [mfaError] - If provided, all blocked operations will fail with this error
  /// instead of resuming successfully.
  Future<Result<void>> resumeBlockedActions([Exception? mfaError]);
}
