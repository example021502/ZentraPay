import 'package:privy_flutter/src/core/privy_plug_in_module.dart';

abstract class AuthRepository extends PrivyPluginModule {
  AuthRepository(super.channelHandler);

  /// Logs out the currently authenticated user.
  Future<void> logout();
}
