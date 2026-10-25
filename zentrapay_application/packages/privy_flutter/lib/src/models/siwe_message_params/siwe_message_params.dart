/// Parameters for generating a SIWE message.
class SiweMessageParams {
  /// The app's domain, e.g. "my-domain.com"
  final String appDomain;

  /// The app's uri, e.g. "https://my-domain.com"
  final String appUri;

  /// EVM Chain ID, e.g. "1" for Ethereum Mainnet
  final String chainId;

  /// The wallet's address being used to sign in
  final String walletAddress;

  const SiweMessageParams({
    required this.appDomain,
    required this.appUri,
    required this.chainId,
    required this.walletAddress,
  });

  /// Convert to JSON for sending via Method Channel
  Map<String, dynamic> toJson() => {
        "appDomain": appDomain,
        "appUri": appUri,
        "chainId": chainId,
        "walletAddress": walletAddress,
      };

  /// Create `SiweMessageParams` from JSON
  factory SiweMessageParams.fromJson(Map<String, dynamic> json) {
    return SiweMessageParams(
      appDomain: json["appDomain"] as String,
      appUri: json["appUri"] as String,
      chainId: json["chainId"] as String,
      walletAddress: json["walletAddress"] as String,
    );
  }
}
