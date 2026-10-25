import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/logging/real_privy_logger.dart';
import 'package:privy_flutter/src/models/auth_state/auth_state.dart';
import 'package:privy_flutter/src/models/privy_config/privy_config.model.dart';
import 'package:privy_flutter/src/modules/auth/auth_manager.dart';
import 'package:privy_flutter/src/modules/auth/auth_state_manager.dart';
import 'package:privy_flutter/src/modules/custom_auth/login_with_custom_auth.dart';
import 'package:privy_flutter/src/modules/custom_auth/real_login_with_custom_auth.dart';
import 'package:privy_flutter/src/modules/email/login_with_email.dart';
import 'package:privy_flutter/src/modules/email/real_login_with_email.dart';
import 'package:privy_flutter/src/modules/login_with_siwe/login_with_siwe.dart';
import 'package:privy_flutter/src/modules/login_with_siwe/real_login_with_siwe.dart';
import 'package:privy_flutter/src/modules/login_with_siws/login_with_siws.dart';
import 'package:privy_flutter/src/modules/login_with_siws/real_login_with_siws.dart';
import 'package:privy_flutter/src/modules/mfa/privy_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/real_privy_mfa.dart';
import 'package:privy_flutter/src/modules/oauth/login_with_oauth.dart';
import 'package:privy_flutter/src/modules/oauth/real_login_with_oauth.dart';
import 'package:privy_flutter/src/modules/passkey/login_with_passkey.dart';
import 'package:privy_flutter/src/modules/passkey/real_login_with_passkey.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';
import 'package:privy_flutter/src/modules/sms/login_with_sms.dart';
import 'package:privy_flutter/src/modules/sms/real_login_with_sms.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/privy.dart';
import 'package:privy_flutter/src/version/privy_version.dart';

/// Implementation of the Privy SDK interface.
class PrivyImpl implements Privy {
  /// Configuration for initializing the Privy SDK.
  final PrivyConfig config;

  /// Handles communication with the native MethodChannel.
  final MethodChannelHandler _channelHandler;

  /// Manages authentication state updates received from the native side.
  late final AuthStateManager authStateManager;

  /// Handles email authentication operations.
  @override
  late final LoginWithEmail email;

  /// Handles SMS authentication operations.
  @override
  late final LoginWithSms sms;

  /// Handles custom authentication operations.
  @override
  late final LoginWithCustomAuth customAuth;

  /// Handles OAuth authentication operations.
  @override
  late final LoginWithOAuth oAuth;

  /// Handles passkey authentication operations.
  @override
  late final LoginWithPasskey passkey;

  /// Handles SIWE authentication operations.
  @override
  late final LoginWithSiwe siwe;

  /// Handles SIWS authentication operations.
  @override
  late final LoginWithSiws siws;

  /// Handles MFA configuration and blocked action resumption.
  @override
  late final PrivyMfa mfa;

  /// Returns the current authentication state.
  @override
  AuthState get currentAuthState => authStateManager.currentAuthState;

  /// Provides a stream of authentication state updates.
  @override
  Stream<AuthState> get authStateStream => authStateManager.authStateStream;

  /// Returns `true` if Privy SDK is initialized and ready.
  @override
  bool get isReady => currentAuthState is! NotReady;

  /// Get the current user from the authState
  @override
  PrivyUser? get user {
    final state = authStateManager.currentAuthState;
    return state is Authenticated ? state.user : null;
  }

  /// **Factory constructor** to ensure Privy is initialized before creating AuthStateManager.
  factory PrivyImpl(PrivyConfig config) {
    LoggerService.initializeLogger(
      RealPrivyLogger(level: config.logLevel, appId: config.appId),
    );
    final channelHandler = MethodChannelHandler();
    final mfaHandler = RealPrivyMfa(
      channelHandler,
      initialConfig: config.mfaConfig,
    );

    _setupNativeCallHandler(channelHandler, config, mfaHandler);

    channelHandler
        .invokeMethod('setPubDevVersion', {"sdkVersion": privySdkVersion});

    // Initialize Privy before creating AuthStateManager

    channelHandler.invokeMethod('initializePrivy', config);

    // Initialize dependencies
    final authStateManager = AuthStateManager();
    final authManager =
        AuthManager(authStateManager, channelHandler); // Pass the dependencies
    final emailHandler = RealLoginWithEmail(
        channelHandler, authManager); // Initialize email authentication
    final smsHandler = RealLoginWithSms(
        channelHandler, authManager); // Initialize SMS authentication
    final customAuthHandler = RealLoginWithCustomAuth(
        channelHandler); // Initialize custom authentication
    final oauthHandler = RealLoginWithOAuth(
        channelHandler, authManager); // Initialize OAuth authentication
    final passkeyHandler = RealLoginWithPasskey(
        channelHandler, authManager); // Initialize passkey authentication
    final siweHandler = RealLoginWithSiwe(
        channelHandler, authManager); // Initialize SIWE authentication
    final siwsHandler = RealLoginWithSiws(
        channelHandler, authManager); // Initialize SIWS authentication

    return PrivyImpl._internal(
        config,
        channelHandler,
        authStateManager,
        emailHandler,
        smsHandler,
        customAuthHandler,
        oauthHandler,
        passkeyHandler,
        siweHandler,
        siwsHandler,
        mfaHandler);
  }

  /// **Private constructor** to enforce controlled initialization.
  PrivyImpl._internal(
      this.config,
      this._channelHandler,
      this.authStateManager,
      this.email,
      this.sms,
      this.customAuth,
      this.oAuth,
      this.passkey,
      this.siwe,
      this.siws,
      this.mfa);

  /// Waits for Privy to be ready before proceeding.
  ///
  /// This function listens to the `authStateStream` and waits until the authentication
  /// state is no longer `NotReady`. This ensures that Privy is fully initialized before
  /// executing further operations.
  /// Waits for Privy to be ready before proceeding.
  /// Calls a native function `awaitReady` via MethodChannel and ensures completion before proceeding.
  @override
  Future<void> awaitReady() async {
    LoggerService.debug("Invoking awaitReady method on native platform.");
    try {
      await _channelHandler.invokeMethod<void>('awaitReady');
      await _waitForAuthStateChange();
      LoggerService.debug("awaitReady completed successfully.");
    } catch (e) {
      LoggerService.error("Error in awaitReady: $e");
      throw e.convertToPrivyException("Error in awaitReady");
    }
  }

  @override
  Future<PrivyUser?> getUser() async {
    LoggerService.debug("Invoking getUser method on native platform.");
    try {
      final Map<Object?, Object?>? userData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>('getUser');

      if (userData == null) {
        LoggerService.debug("No user found");
        return null;
      }

      final convertedUser = safeCastToMap(userData);

      final user = RealPrivyUser.fromJson(convertedUser);
      LoggerService.debug("User retrieved successfully: $user");
      return user;
    } catch (e) {
      LoggerService.error("Error in getUser: $e");
      throw e.convertToPrivyException("Error in getUser");
    }
  }

  @override
  Future<AuthState> getAuthState() async {
    LoggerService.debug("Invoking getAuthState method on native platform.");
    try {
      final Map<Object?, Object?>? authStateData = await _channelHandler
          .invokeMethod<Map<Object?, Object?>>('getAuthState');
      if (authStateData == null) {
        throw const PrivyException(
            "Error in getAuthState: Auth state data is null");
      }
      final convertedAuthState = safeCastToMap(authStateData);

      final authState = AuthState.fromJson(convertedAuthState);
      LoggerService.debug("Auth state retrieved successfully: $authState");
      return authState;
    } catch (e) {
      LoggerService.error("Error in getAuthState: $e");
      throw e.convertToPrivyException("Error in getAuthState");
    }
  }

  /// Ensures that `AuthStateManager` has updated before proceeding.
  ///
  /// This function prevents a potential race condition where `awaitReady()`
  /// completes before the authentication state has been fully synchronized.
  /// Since Privy initialization and `AuthStateManager` updates occur asynchronously,
  /// there are cases where `awaitReady()` may return while `authStateStream`
  /// is still in the `NotReady` state.
  ///
  /// By waiting until `authStateStream` emits a state that is **not** `NotReady`,
  /// we ensure that the authentication state is successfully updated before
  /// continuing execution, avoiding unexpected behavior when using Privy.
  Future<void> _waitForAuthStateChange() async {
    LoggerService.debug(
        "Waiting for AuthStateManager to update from NotReady...");

    await authStateManager.authStateStream
        .firstWhere((state) => state is! NotReady);

    LoggerService.debug("AuthStateManager is now updated.");
  }

  /// Logs out the currently authenticated user.
  @override
  Future<void> logout() async {
    LoggerService.debug("Invoking logout method on native platform.");
    try {
      await _channelHandler.invokeMethod<void>('logout');
      LoggerService.debug("User successfully logged out.");
    } catch (e) {
      LoggerService.error("Error during logout: $e");
      throw e.convertToPrivyException("Error during logout");
    }
  }

  /// Private Helper function to set up method call handler for native → Flutter calls.
  static void _setupNativeCallHandler(MethodChannelHandler channelHandler,
      PrivyConfig config, RealPrivyMfa mfaHandler) {
    channelHandler.setMethodCallHandler((call) async {
      if (call.method == 'getCustomAuthToken' &&
          config.customAuthConfig != null) {
        LoggerService.debug("Fetching custom auth token.");
        return await config.customAuthConfig!.tokenProvider();
      }
      if (call.method == 'onMfaRequired') {
        mfaHandler.handleOnMfaRequired(call);
        return null;
      }
      return null;
    });
  }
}
