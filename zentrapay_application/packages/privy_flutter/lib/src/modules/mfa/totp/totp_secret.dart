/// TOTP secret information for enrollment.
///
/// Use [secret] for manual entry or [authUrl] to generate a QR code.
class TotpSecret {
  /// Manual entry key for authenticator apps.
  final String secret;

  /// OTP Auth URL for QR code generation.
  ///
  /// Format: `otpauth://totp/...`
  /// Use this to generate a QR code that users can scan with their
  /// authenticator app.
  final String authUrl;

  const TotpSecret({
    required this.secret,
    required this.authUrl,
  });

  factory TotpSecret.fromJson(Map<String, dynamic> json) {
    return TotpSecret(
      secret: json['secret'] as String,
      authUrl: json['authUrl'] as String,
    );
  }
}
