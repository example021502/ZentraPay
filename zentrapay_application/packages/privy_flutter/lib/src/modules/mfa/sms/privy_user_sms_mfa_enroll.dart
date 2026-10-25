import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';

/// SMS MFA enrollment operations.
///
/// Access via `user.mfa.sms.enroll`.
abstract interface class PrivyUserSmsMfaEnroll extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  PrivyUserSmsMfaEnroll(super.channelHandler);

  /// Send OTP code to [phoneNumber] for enrollment.
  ///
  /// After calling this method, prompt the user to enter the code they received,
  /// then call [submit] to complete enrollment.
  Future<Result<void>> sendCode(String phoneNumber);

  /// Complete SMS MFA enrollment with the verification [code].
  ///
  /// Returns the updated [PrivyUser] with SMS MFA enrolled.
  Future<Result<PrivyUser>> submit({
    required String code,
    required String phoneNumber,
  });
}
