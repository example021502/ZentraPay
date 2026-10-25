import 'package:privy_flutter/src/modules/mfa/sms/privy_user_sms_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/totp/privy_user_totp_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/privy_user_passkeys_mfa.dart';

/// User-specific MFA namespace providing access to different MFA methods for
/// enrollment and verification.
///
/// Access pattern: `user.mfa.totp`, `user.mfa.sms`, `user.mfa.passkeys`
///
/// For global MFA configuration and control (setConfig, resumeBlockedActions),
/// use [PrivyMfa] via `privy.mfa`.
abstract interface class PrivyUserMfa {
  /// TOTP-based MFA enrollment and verification.
  PrivyUserTotpMfa get totp;

  /// SMS-based MFA enrollment and verification.
  PrivyUserSmsMfa get sms;

  /// Passkey-based MFA enrollment and verification.
  PrivyUserPasskeysMfa get passkeys;
}
