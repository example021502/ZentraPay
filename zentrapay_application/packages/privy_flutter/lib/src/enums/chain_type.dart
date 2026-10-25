import 'package:flutter/foundation.dart';

enum ChainType {
  ethereum,
  solana;

  /// Convert enum to string for JSON serialization
  String toJson() {
    return name; // This will return "Ethereum" or "Solana"
  }

  /// Convert string to `ChainType` safely
  static ChainType fromJson(String chainType) {
    switch (chainType) {
      case "Ethereum":
        return ChainType.ethereum;
      case "Solana":
        return ChainType.solana;
      default:
        debugPrint('Unknown ChainType: $chainType');
        return ChainType.ethereum;
    }
  }
}
