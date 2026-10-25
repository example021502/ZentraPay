import 'dart:io';

import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/models/oauth_provider/oauth_provider.dart';
import 'package:privy_flutter/src/modules/auth/auth_manager.dart';
import 'package:privy_flutter/src/modules/auth/link_type.dart';
import 'package:privy_flutter/src/modules/auth/unlink_type.dart';
import 'package:privy_flutter/src/modules/oauth/login_with_oauth.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Implementation of the `LoginWithOAuth` interface that interacts with the
/// native platform using method channels.
class RealLoginWithOAuth implements LoginWithOAuth {
  final MethodChannelHandler _channelHandler;
  final AuthManager _authManager;

  /// Constructor that initializes the method channel handler for communication.
  RealLoginWithOAuth(this._channelHandler, this._authManager);

  /// Initiates the OAuth login flow with the specified provider.
  ///
  /// [provider] - The OAuth provider to use (e.g., OAuthProvider.google)
  /// [appUrlScheme] - Optional custom URL scheme for redirecting back to the app
  /// Returns a `Result<PrivyUser>` containing the authenticated user or an error.
  @override
  Future<Result<PrivyUser>> login(
      {required OAuthProvider provider, required String appUrlScheme}) async {
    LoggerService.debug(
        "Initiating OAuth login with provider: ${provider.name}");
    // Check if Apple Sign In is attempted on Android
    if (provider == OAuthProvider.apple && Platform.isAndroid) {
      LoggerService.error("Apple Sign In is only supported on iOS");
      return const Failure(PrivyException(
        'Apple Sign In is only supported on iOS',
      ));
    }

    try {
      final Map<Object?, Object?>? responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'oauthLogin',
        {
          'provider': provider.name,
          'appUrlScheme': appUrlScheme,
        },
      );

      LoggerService.debug("Received response from oauthLogin: $responseData");

      // Convert response data into a `PrivyUser` instance.
      final convertedUser = safeCastToMap(responseData);

      LoggerService.debug(
          "Successfully logged in user with OAuth. User data: $convertedUser");
      return Success(RealPrivyUser.fromJson(convertedUser));
    } catch (e) {
      LoggerService.error("OAuth login failed with exception: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  @override
  Future<Result<PrivyUser>> link(
      {required OAuthProvider provider, required String appUrlScheme}) async {
    LoggerService.debug("Attempting to link OAuth provider: ${provider.name}");

    if (provider == OAuthProvider.apple && Platform.isAndroid) {
      LoggerService.error("Apple Sign In is only supported on iOS");
      return const Failure(PrivyException(
        'Apple Sign In is only supported on iOS',
      ));
    }

    return _authManager
        .link(OAuthLink(provider: provider.name, appUrlScheme: appUrlScheme));
  }

  @override
  Future<Result<PrivyUser>> unlink(
      {required OAuthProvider provider, required String subject}) async {
    LoggerService.debug(
        "Attempting to unlink OAuth provider: ${provider.name}");

    return _authManager
        .unlink(OAuthUnlink(provider: provider.name, subject: subject));
  }
}
