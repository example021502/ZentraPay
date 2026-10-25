import 'package:privy_flutter/src/utils/method_channel_handler.dart';

/// An abstract class that serves as a base for all Privy plugin modules.
/// This ensures that every module requiring method channel communication
/// has a consistent way of interacting with the native platform.
abstract class PrivyPluginModule {
  /// Handles method channel communication between Flutter and native code.
  // ignore: unused_field
  final MethodChannelHandler _channelHandler;

  /// Constructor that requires a [MethodChannelHandler] to be passed in.
  /// This enforces dependency injection, making it easier to test and manage.
  PrivyPluginModule(this._channelHandler);
}
