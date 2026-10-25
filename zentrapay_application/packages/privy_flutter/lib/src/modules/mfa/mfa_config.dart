import 'package:privy_flutter/src/modules/mfa/mfa_listener.dart';

/// Configuration for MFA behavior.
///
/// Use this to configure how the SDK handles MFA verification requirements,
/// including the listener that receives MFA prompts and the timeout duration.
class MfaConfig {
  /// Listener called when MFA verification is required.
  ///
  /// This listener will be invoked whenever an operation requires MFA verification.
  /// See [MfaListener] for implementation details.
  final MfaListener listener;

  /// Timeout for MFA verification.
  ///
  /// Operations blocked waiting for MFA verification will fail with a timeout
  /// error if not completed within this duration. Defaults to 5 minutes.
  final Duration timeout;

  const MfaConfig({
    required this.listener,
    this.timeout = const Duration(minutes: 5),
  });
}
