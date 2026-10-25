import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/privy_user_passkeys_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/mfa/passkey/privy_user_passkeys_mfa_verify.dart';

/// Passkey MFA operations.
///
/// Access via `user.mfa.passkeys`.
abstract interface class PrivyUserPasskeysMfa extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  PrivyUserPasskeysMfa(super.channelHandler);

  /// Enrollment operations for Passkey MFA.
  PrivyUserPasskeysMfaEnroll get enroll;

  /// Verification operations for Passkey MFA.
  PrivyUserPasskeysMfaVerify get verify;

  /// Remove Passkey MFA from the user's account.
  ///
  /// If [removeForLogin] is true (default), the passkey is also removed as a
  /// login method. Set to false to keep the passkey for login while removing
  /// it from MFA.
  ///
  /// Returns the updated [PrivyUser] with Passkey MFA removed.
  Future<Result<PrivyUser>> unenroll({bool removeForLogin = true});
}
