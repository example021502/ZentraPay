import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/mfa/totp/privy_user_totp_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/mfa/totp/privy_user_totp_mfa_verify.dart';

/// TOTP MFA operations.
///
/// Access via `user.mfa.totp`.
abstract interface class PrivyUserTotpMfa extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  PrivyUserTotpMfa(super.channelHandler);

  /// Enrollment operations for TOTP MFA.
  PrivyUserTotpMfaEnroll get enroll;

  /// Verification operations for TOTP MFA.
  PrivyUserTotpMfaVerify get verify;

  /// Remove TOTP MFA from the user's account.
  ///
  /// Returns the updated [PrivyUser] with TOTP MFA removed.
  Future<Result<PrivyUser>> unenroll();
}
