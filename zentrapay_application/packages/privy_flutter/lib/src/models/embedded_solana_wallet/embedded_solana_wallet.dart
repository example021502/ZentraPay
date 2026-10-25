import 'package:privy_flutter/src/enums/chain_type.dart';
import 'package:privy_flutter/src/models/embedded_wallet/embedded_wallet.dart';
import 'package:privy_flutter/src/modules/embedded_solana_wallet_provider/real_embedded_solana_wallet_provider.dart';
import 'package:privy_flutter/src/modules/embedded_solana_wallet_provider/embedded_solana_wallet_provider.dart';

/// **Solana-specific embedded wallet implementation.**
class EmbeddedSolanaWallet extends EmbeddedWallet {
  final EmbeddedSolanaWalletProvider provider;

  /// **Constructor**
  EmbeddedSolanaWallet({
    super.id,
    required super.address,
    super.chainId,
    super.recoveryMethod,
    required super.hdWalletIndex,
  })  : provider = RealEmbeddedSolanaWalletProvider(walletAddress: address),
        super(chainType: ChainType.solana);

  /// **Factory constructor to create `EmbeddedSolanaWallet` from JSON**
  factory EmbeddedSolanaWallet.fromJson(Map<String, dynamic> json) {
    return EmbeddedSolanaWallet(
      id: json['id'] as String?,
      address: json['address'] as String,
      chainId: json['chainId'] as String?,
      recoveryMethod: json['recoveryMethod'] as String?,
      hdWalletIndex: json['hdWalletIndex'] as int,
    );
  }
}
