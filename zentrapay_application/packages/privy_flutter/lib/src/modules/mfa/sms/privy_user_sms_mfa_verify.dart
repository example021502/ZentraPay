import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// SMS MFA verification operations.
///
/// Access via `user.mfa.sms.verify`.
///
/// Use these methods when the SDK triggers [MfaListener.onMfaRequired] and
/// the user chooses to verify via SMS.
abstract interface class PrivyUserSmsMfaVerify extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  PrivyUserSmsMfaVerify(super.channelHandler);

  /// Send OTP code to the user's enrolled phone number.
  ///
  /// After calling this method, prompt the user to enter the code they received,
  /// then call [submit] to complete verification.
  Future<Result<void>> sendCode();

  /// Verify SMS MFA with the OTP [code].
  ///
  /// After successful verification, call [PrivyMfa.resumeBlockedActions] to
  /// unblock any pending operations.
  Future<Result<void>> submit(String code);
}
