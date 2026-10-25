import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/utils/result.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';

/// Passkey MFA enrollment operations.
///
/// Access via `user.mfa.passkeys.enroll`.
abstract interface class PrivyUserPasskeysMfaEnroll extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  PrivyUserPasskeysMfaEnroll(super.channelHandler);

  /// Enroll existing passkey credential IDs for MFA.
  ///
  /// The [credentialIds] should be the IDs of passkeys that were previously
  /// registered for login. This enables those passkeys to also be used for
  /// MFA verification.
  ///
  /// Returns the updated [PrivyUser] with Passkey MFA enrolled.
  Future<Result<PrivyUser>> submit(List<String> credentialIds);
}
