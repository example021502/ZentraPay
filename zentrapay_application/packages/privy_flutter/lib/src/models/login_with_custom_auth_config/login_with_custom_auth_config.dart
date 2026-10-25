///  Custom Auth Configuration (Not Serialized)
class LoginWithCustomAuthConfig {
  /// The callback function that provides the current user's access token.
  /// Returns `null` if the user is unauthenticated.
  final TokenProvider tokenProvider;

  const LoginWithCustomAuthConfig({required this.tokenProvider});
}

typedef TokenProvider = Future<String?> Function();
