import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/models/auth_state/auth_state.dart';
import 'package:privy_flutter/src/modules/auth/auth_state_manager.dart';
import 'package:privy_flutter/src/modules/auth/link_type.dart';
import 'package:privy_flutter/src/modules/auth/unlink_type.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Interface for AuthManager to allow for dependency injection
/// and easier testing.
abstract class IAuthManager {
  /// Get the current authenticated user
  PrivyUser? get currentUser;

  /// Refresh the current user's data
  Future<Result<void>> refreshUser();

  /// Links an account to the current user
  Future<Result<PrivyUser>> link(LinkType type);

  /// Unlinks an account from the current user
  Future<Result<PrivyUser>> unlink(UnlinkType type);
}

/// **AuthManager provides centralized access to refresh the Privy user.**
///
/// This class provides refresh functionality for the currently authenticated user
/// across different auth modules.
class AuthManager implements IAuthManager {
  final AuthStateManager _authStateManager;
  final MethodChannelHandler _channelHandler;

  AuthManager(this._authStateManager, this._channelHandler);

  @override
  PrivyUser? get currentUser {
    final authState = _authStateManager.currentAuthState;
    return authState is Authenticated ? authState.user : null;
  }

  /// Refreshes the current user's data
  ///
  /// Returns a [Result] indicating success or failure
  @override
  Future<Result<void>> refreshUser() async {
    final user = currentUser;
    if (user == null) {
      LoggerService.warning(
          'AuthManager: Cannot refresh user, no user is currently authenticated');
      return const Failure(
          PrivyException('No user is currently authenticated'));
    }

    try {
      // Call refresh on the user object directly
      final result = await user.refresh();
      if (result is Success) {
        LoggerService.debug('AuthManager: User refreshed successfully');

        // Force auth state stream update after successful refresh
        final currentState = _authStateManager.currentAuthState;
        if (currentState is Authenticated) {
          _authStateManager.updateAuthState(Authenticated(user));
        }
      }
      return result;
    } catch (e) {
      LoggerService.error('AuthManager: Failed to refresh user: $e');
      return Failure(e.convertToPrivyException());
    }
  }

  /// Links an account to the current user.
  ///
  /// Returns a [Result] containing the updated [PrivyUser] on success.
  @override
  Future<Result<PrivyUser>> link(LinkType linkType) async {
    try {
      LoggerService.debug(
          'Invoking method channel for ${linkType.methodName}.');
      final responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        linkType.methodName,
        linkType.params,
      );
      LoggerService.debug(
          'Received response from ${linkType.methodName}: $responseData');
      final convertedUser = safeCastToMap(responseData);
      final user = RealPrivyUser.fromJson(convertedUser);
      LoggerService.debug(
          'Successfully linked via ${linkType.methodName}. User data: $convertedUser');
      return Success(user);
    } catch (e) {
      LoggerService.error('AuthManager: ${linkType.methodName} failed: $e');
      return Failure(e.convertToPrivyException());
    }
  }

  /// Unlinks an account from the current user.
  ///
  /// Returns a [Result] containing the updated [PrivyUser] on success.
  @override
  Future<Result<PrivyUser>> unlink(UnlinkType unlinkType) async {
    try {
      LoggerService.debug(
          'Invoking method channel for ${unlinkType.methodName}.');
      final responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        unlinkType.methodName,
        unlinkType.params,
      );
      LoggerService.debug(
          'Received response from ${unlinkType.methodName}: $responseData');
      final convertedUser = safeCastToMap(responseData);
      final user = RealPrivyUser.fromJson(convertedUser);
      LoggerService.debug(
          'Successfully unlinked via ${unlinkType.methodName}. User data: $convertedUser');
      return Success(user);
    } catch (e) {
      LoggerService.error('AuthManager: ${unlinkType.methodName} failed: $e');
      return Failure(e.convertToPrivyException());
    }
  }
}
