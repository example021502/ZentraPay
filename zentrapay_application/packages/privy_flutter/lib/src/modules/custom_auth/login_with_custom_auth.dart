import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Handles custom authentication operations.
abstract interface class LoginWithCustomAuth extends PrivyPluginModule {
  LoginWithCustomAuth(super.channelHandler);

  /// Logs in with a custom access token.
  Future<Result<PrivyUser>> loginWithCustomAccessToken();
}
