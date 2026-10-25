/// Enum representing the supported OAuth providers for authentication.
/// Developers can use these values when implementing OAuth-based login flows.
enum OAuthProvider {
  /// Google OAuth provider
  google,

  /// Twitter OAuth provider
  twitter,

  /// Discord OAuth provider
  discord,

  /// Apple OAuth provider (iOS only)
  apple,

  /// Telegram OAuth provider
  telegram,
}
