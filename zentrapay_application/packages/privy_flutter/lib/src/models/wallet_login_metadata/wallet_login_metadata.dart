import '../wallet_client_type/wallet_client_type.dart';

/// Metadata for wallet login, providing optional details about the wallet client and connection method.
class WalletLoginMetadata {
  final WalletClientType? walletClientType;
  final String? connectorType;

  const WalletLoginMetadata({
    this.walletClientType,
    this.connectorType,
  });

  /// Convert to JSON for sending via Method Channel
  Map<String, dynamic> toJson() => {
        "walletClientType": walletClientType?.rawValue,
        "connectorType": connectorType,
      };

  /// Create `WalletLoginMetadata` from JSON
  factory WalletLoginMetadata.fromJson(Map<String, dynamic> json) {
    return WalletLoginMetadata(
      walletClientType:
          WalletClientType.fromString(json["walletClientType"] as String?),
      connectorType: json["connectorType"] as String?,
    );
  }
}
