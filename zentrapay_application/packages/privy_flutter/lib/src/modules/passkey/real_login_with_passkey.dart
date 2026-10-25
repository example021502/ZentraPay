import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/auth/auth_manager.dart';
import 'package:privy_flutter/src/modules/auth/link_type.dart';
import 'package:privy_flutter/src/modules/auth/unlink_type.dart';
import 'package:privy_flutter/src/modules/passkey/login_with_passkey.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Implementation of the `LoginWithPasskey` interface that interacts with the
/// native platform using method channels.
class RealLoginWithPasskey implements LoginWithPasskey {
  final MethodChannelHandler _channelHandler;
  final AuthManager _authManager;

  /// Constructor that initializes the method channel handler for communication.
  RealLoginWithPasskey(this._channelHandler, this._authManager);

  /// Signs up a new user with a passkey.
  ///
  /// Returns a `Result<PrivyUser>` representing the success or failure of the signup.
  @override
  Future<Result<PrivyUser>> signup({
    required String relyingParty,
    String? displayName,
  }) async {
    LoggerService.debug(
        "Attempting passkey signup. Relying Party: $relyingParty, Display Name: $displayName");

    if (relyingParty.isEmpty) {
      LoggerService.error("signup failed: Relying party is empty.");
      return const Failure(PrivyException("Relying party is required"));
    }

    try {
      LoggerService.debug("Invoking method channel for passkeySignup.");
      final Map<Object?, Object?>? responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'passkeySignup',
        {
          'relyingParty': relyingParty,
          if (displayName != null) 'displayName': displayName,
        },
      );

      LoggerService.debug(
          "Received response from passkeySignup: $responseData");
      // Convert response data into a `PrivyUser` instance.
      final convertedUser = safeCastToMap(responseData);

      LoggerService.debug(
          "Successfully signed up user with passkey. User data: $convertedUser");
      return Success(RealPrivyUser.fromJson(convertedUser));
    } catch (e) {
      LoggerService.error("signup failed with exception: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// Logs in an existing user with their passkey.
  ///
  /// Returns a `Result<PrivyUser>` representing the success or failure of the login.
  @override
  Future<Result<PrivyUser>> login({
    required String relyingParty,
  }) async {
    LoggerService.debug(
        "Attempting passkey login. Relying Party: $relyingParty");

    if (relyingParty.isEmpty) {
      LoggerService.error("login failed: Relying party is empty.");
      return const Failure(PrivyException("Relying party is required"));
    }

    try {
      LoggerService.debug("Invoking method channel for passkeyLogin.");
      final Map<Object?, Object?>? responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'passkeyLogin',
        {
          'relyingParty': relyingParty,
        },
      );

      LoggerService.debug("Received response from passkeyLogin: $responseData");
      // Convert response data into a `PrivyUser` instance.
      final convertedUser = safeCastToMap(responseData);

      LoggerService.debug(
          "Successfully logged in user with passkey. User data: $convertedUser");
      return Success(RealPrivyUser.fromJson(convertedUser));
    } catch (e) {
      LoggerService.error("login failed with exception: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// Links a passkey to the currently authenticated user.
  ///
  /// Returns a `Result<PrivyUser>` representing the success or failure of the link operation.
  @override
  Future<Result<PrivyUser>> link({
    required String relyingParty,
    String? displayName,
  }) async {
    LoggerService.debug(
        "Attempting passkey link. Relying Party: $relyingParty, Display Name: $displayName");

    if (relyingParty.isEmpty) {
      LoggerService.error("link failed: Relying party is empty.");
      return const Failure(PrivyException("Relying party is required"));
    }

    return _authManager.link(PasskeyLink(
      relyingParty: relyingParty,
      displayName: displayName,
    ));
  }

  /// Unlinks a passkey from the currently authenticated user.
  ///
  /// Returns a `Result<PrivyUser>` representing the success or failure of the unlink operation.
  @override
  Future<Result<PrivyUser>> unlink({
    required String credentialId,
  }) async {
    LoggerService.debug(
        "Attempting passkey unlink. Credential ID: $credentialId");

    return _authManager.unlink(PasskeyUnlink(credentialId: credentialId));
  }
}
