import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';

/// Delegate interface for handling MFA verification prompts.
///
/// Implement this interface to receive callbacks when operations require MFA
/// verification. When configured via [MfaConfig], the SDK will call
/// [onMfaRequired] when an operation needs MFA verification.
///
/// ## Important
///
/// **You MUST call [PrivyMfa.resumeBlockedActions]** after [onMfaRequired] is
/// invoked. Failure to do so will cause blocked operations to hang until timeout.
///
/// **Concurrent operations:** This method may be called multiple times if
/// multiple operations require MFA simultaneously. Your implementation should
/// handle this gracefully (e.g., show only one MFA prompt). A single call to
/// [PrivyMfa.resumeBlockedActions] will resume all pending operations.
///
/// **Timeout:** If [PrivyMfa.resumeBlockedActions] is not called within the
/// configured timeout (default 5 minutes), blocked operations will fail with
/// a timeout error.
///
/// ## Verification Flow
///
/// When [onMfaRequired] is called:
/// 1. Present MFA UI to the user based on `user.mfaMethods`
/// 2. Call the appropriate verification method:
///    - `user.mfa.sms.verify.sendCode()` then `user.mfa.sms.verify.submit(code)`
///    - `user.mfa.totp.verify.submit(code)`
///    - `user.mfa.passkeys.verify.submit()`
/// 3. **Always** call `privy.mfa.resumeBlockedActions()` afterward
///
///
/// ### Implementing the interface (for complex cases)
///
/// ```dart
/// class MyMfaHandler implements MfaListener {
///   bool _isShowing = false;
///
///   @override
///   void onMfaRequired(PrivyUser user) {
///     if (_isShowing) return; // Prevent multiple prompts
///     _isShowing = true;
///     // Show MFA UI...
///   }
/// }
///
/// // Then use it:
/// mfaConfig: MfaConfig(listener: MyMfaHandler()),
/// ```
///
/// See also: [CallbackMfaListener], [PrivyMfa.resumeBlockedActions], [MfaConfig]
abstract interface class MfaListener {
  /// Called when an operation requires MFA verification.
  ///
  /// Present MFA verification UI to the user and guide them through one of
  /// the available MFA methods from `user.mfaMethods`. Once verification
  /// completes (success or failure), call [PrivyMfa.resumeBlockedActions].
  ///
  /// This method may be called multiple times concurrently. Your implementation
  /// should handle this by showing a single MFA prompt and ignoring subsequent
  /// calls while it's visible.
  ///
  /// [user] The authenticated user requiring MFA. Access `user.mfaMethods`
  /// to determine which verification options to present.
  void onMfaRequired(PrivyUser user);
}
