import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';

/// Base class representing different authentication states.
sealed class AuthState {
  const AuthState();

  /// Factory constructor to create an AuthState from JSON
  factory AuthState.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    switch (type) {
      case 'NotReady':
        return const NotReady();
      case 'Unauthenticated':
        return const Unauthenticated();
      case 'AuthenticatedUnverified':
        return const AuthenticatedUnverified();
      case 'Authenticated':
        final userData = json['user'] as Map<Object?, Object?>?;
        if (userData == null) {
          throw ArgumentError('Authenticated state must include user data');
        }
        final serializedUser = safeCastToMap(userData);
        return Authenticated(RealPrivyUser.fromJson(serializedUser));
      default:
        throw ArgumentError('Unknown AuthState type: $type');
    }
  }
}

/// Represents the initial state before authentication status is determined.
class NotReady extends AuthState {
  const NotReady();
}

/// Represents the state when the user is not authenticated.
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthenticatedUnverified extends AuthState {
  const AuthenticatedUnverified();
}

/// Represents the state when the user is authenticated.
class Authenticated extends AuthState {
  final PrivyUser user;

  /// Constructor accepting the authenticated user's details.
  const Authenticated(this.user);
}

/// Extension on AuthState to provide helper methods.
extension AuthStateExtension on AuthState {
  /// Checks whether the current state represents an authenticated user.
  bool get isAuthenticated => this is Authenticated;

  /// Returns the user if authenticated, otherwise returns null.
  PrivyUser? get user =>
      this is Authenticated ? (this as Authenticated).user : null;
}
