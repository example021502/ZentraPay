/// Parameters for generating a SIWS (Sign-In With Solana) message.
class SiwsMessageParams {
  /// The app's domain, e.g. "my-domain.com"
  final String appDomain;

  /// The app's uri, e.g. "https://my-domain.com"
  final String appUri;

  /// The Solana wallet's address being used to sign in
  final String walletAddress;

  const SiwsMessageParams({
    required this.appDomain,
    required this.appUri,
    required this.walletAddress,
  });

  /// Convert to JSON for sending via Method Channel
  Map<String, dynamic> toJson() => {
        "appDomain": appDomain,
        "appUri": appUri,
        "walletAddress": walletAddress,
      };

  /// Create `SiwsMessageParams` from JSON
  factory SiwsMessageParams.fromJson(Map<String, dynamic> json) {
    return SiwsMessageParams(
      appDomain: json["appDomain"] as String,
      appUri: json["appUri"] as String,
      walletAddress: json["walletAddress"] as String,
    );
  }
}
