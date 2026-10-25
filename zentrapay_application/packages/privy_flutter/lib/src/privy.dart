import 'package:privy_flutter/src/models/auth_state/auth_state.dart';
import 'package:privy_flutter/src/models/privy_config/privy_config.model.dart';
import 'package:privy_flutter/src/modules/custom_auth/login_with_custom_auth.dart';
import 'package:privy_flutter/src/modules/email/login_with_email.dart';
import 'package:privy_flutter/src/modules/login_with_siwe/login_with_siwe.dart';
import 'package:privy_flutter/src/modules/login_with_siws/login_with_siws.dart';
import 'package:privy_flutter/src/modules/mfa/privy_mfa.dart';
import 'package:privy_flutter/src/modules/oauth/login_with_oauth.dart';
import 'package:privy_flutter/src/modules/passkey/login_with_passkey.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/sms/login_with_sms.dart';
import 'package:privy_flutter/src/privy_impl.dart';

abstract interface class Privy {
  // Initialize the Privy SDK.
  static Privy init({
    required PrivyConfig config,
  }) {
    return PrivyImpl(config);
  }

  /// Waits for Privy to be ready before proceeding.
  ///
  /// This function listens to the `authStateStream` and waits until the authentication
  /// state is no longer `NotReady`. This ensures that Privy is fully initialized before
  /// executing further operations.
  @Deprecated(
      "Calling getAuthState() will handle awaiting ready under the hood.")
  Future<void> awaitReady();

  // Logout the current user.
  Future<void> logout();

  // get the auth state of the user.
  Future<AuthState> getAuthState();

  Future<PrivyUser?> getUser();

  // Get the current authentication state.
  AuthState get currentAuthState;

  // A stream for auth state updates.
  Stream<AuthState> get authStateStream;

  // Login with email.
  LoginWithEmail get email;

  // Login with custom auth.
  LoginWithCustomAuth get customAuth;

  // Login with SMS.
  LoginWithSms get sms;

  // Login with OAuth providers.
  LoginWithOAuth get oAuth;

  // Login with passkey.
  LoginWithPasskey get passkey;

  // Login with SIWE.
  LoginWithSiwe get siwe;

  // Login with SIWS.
  LoginWithSiws get siws;

  // MFA configuration and control.
  PrivyMfa get mfa;

  // Check if the Privy SDK is ready.
  @Deprecated(
      "It's no longer required to check ready state prior to checking the user's AuthState anymore. Instead, users should use getAuthState()")
  bool get isReady;

  @Deprecated(
      "Calling await privy.getUser() will handle awaiting ready under the hood.")
  PrivyUser? get user;
}
