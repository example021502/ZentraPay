import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/models/oauth_provider/oauth_provider.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Defines the interface for OAuth-based authentication.
abstract interface class LoginWithOAuth extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  LoginWithOAuth(super.channelHandler);

  /// Initiates the OAuth login flow with the specified provider.
  ///
  /// [provider] - The OAuth provider to use (e.g., OAuthProvider.google)
  /// [appUrlScheme] - Optional custom URL scheme for redirecting back to the app
  /// Returns a `Result<PrivyUser>` containing the authenticated user or an error.
  Future<Result<PrivyUser>> login(
      {required OAuthProvider provider, required String appUrlScheme});

  /// Links an OAuth provider to the currently authenticated user's account.
  ///
  /// [provider] - The OAuth provider to link (e.g., OAuthProvider.google)
  /// [appUrlScheme] - Optional custom URL scheme for redirecting back to the app
  /// Returns a `Result<PrivyUser>` containing the updated user if successful.
  Future<Result<PrivyUser>> link(
      {required OAuthProvider provider, required String appUrlScheme});

  /// Unlinks an OAuth provider from the currently authenticated user's account.
  ///
  /// [provider] - The OAuth provider to unlink.
  /// [subject] - The subject identifier of the linked OAuth account to unlink.
  /// Returns a `Result<PrivyUser>` containing the updated user if successful.
  Future<Result<PrivyUser>> unlink(
      {required OAuthProvider provider, required String subject});
}
