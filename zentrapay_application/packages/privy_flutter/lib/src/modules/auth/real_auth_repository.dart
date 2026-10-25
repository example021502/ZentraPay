import 'package:privy_flutter/privy_flutter.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';

import 'auth_repository.dart';

class RealAuthRepository implements AuthRepository {
  final MethodChannelHandler _channelHandler;

  RealAuthRepository(this._channelHandler);

  /// Logs out the currently authenticated user.
  ///
  /// Returns a [Result] indicating success or failure.
  @override
  Future<Result<void>> logout() async {
    LoggerService.debug("Attempting user logout.");

    try {
      await _channelHandler.invokeMethod<void>('logout');
      LoggerService.debug("User successfully logged out.");
      return const Success(null);
    } catch (e) {
      LoggerService.error("Logout failed with exception: $e");
      // Handles errors from the native platform during logout.
      return Failure(e.convertToPrivyException("Logout failed"));
    }
  }
}
