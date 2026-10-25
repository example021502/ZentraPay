import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/mfa/sms/privy_user_sms_mfa_enroll.dart';
import 'package:privy_flutter/src/modules/mfa/sms/privy_user_sms_mfa_verify.dart';

/// SMS MFA operations.
///
/// Access via `user.mfa.sms`.
abstract interface class PrivyUserSmsMfa extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  PrivyUserSmsMfa(super.channelHandler);

  /// Enrollment operations for SMS MFA.
  PrivyUserSmsMfaEnroll get enroll;

  /// Verification operations for SMS MFA.
  PrivyUserSmsMfaVerify get verify;

  /// Remove SMS MFA from the user's account.
  ///
  /// Returns the updated [PrivyUser] with SMS MFA removed.
  Future<Result<PrivyUser>> unenroll();
}
