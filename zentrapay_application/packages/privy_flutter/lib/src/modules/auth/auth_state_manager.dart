import 'package:flutter/services.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/models/auth_state/auth_state.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';
import 'package:rxdart/rxdart.dart';

class AuthStateManager {
  static const _authStateChannel = EventChannel('privy_flutter/authState');

  AuthState get currentAuthState => _authStateSubject.value;
  final _authStateSubject = BehaviorSubject<AuthState>.seeded(const NotReady());

  AuthStateManager() {
    _authStateChannel.receiveBroadcastStream().distinct().listen((event) {
      final eventType = event['type'] as String;

      late final AuthState authState;

      switch (eventType) {
        case 'NotReady':
          LoggerService.debug("Auth state changed to: NotReady");
          authState = const NotReady();
          break;
        case 'Unauthenticated':
          LoggerService.debug("Auth state changed to: Unauthenticated");
          authState = const Unauthenticated();
          break;
        case 'AuthenticatedUnverified':
          LoggerService.debug("Auth state changed to: AuthenticatedUnverified");
          authState = const AuthenticatedUnverified();
          break;
        case 'Authenticated':
          final user = event['user'];
          final convertedUser = safeCastToMap(user);
          LoggerService.debug(
              "Auth state changed to: Authenticated. User data: $convertedUser");
          authState = Authenticated(RealPrivyUser.fromJson(convertedUser));
          break;
        default:
          // Log an error if the received auth state is not recognized.
          LoggerService.error("Unknown auth state received: $eventType");
      }

      _authStateSubject.add(authState);
    });
  }

  Stream<AuthState> get authStateStream => _authStateSubject.stream;

  /// Manually update the auth state - useful for when user data changes
  /// outside of native auth state broadcasts (e.g., during refresh operations)
  void updateAuthState(AuthState newState) {
    _authStateSubject.add(newState);
  }
}
