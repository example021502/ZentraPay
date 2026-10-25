import 'package:privy_flutter/src/enums/chain_type.dart';
import 'package:privy_flutter/src/models/embedded_wallet/embedded_wallet.dart';
import 'package:privy_flutter/src/modules/embedded_ethereum_wallet_provider/embedded_ethereum_wallet_provider.dart';
import 'package:privy_flutter/src/modules/embedded_ethereum_wallet_provider/real_embedded_ethereum_wallet_provider.dart';

/// **Ethereum-specific embedded wallet implementation.**
class EmbeddedEthereumWallet extends EmbeddedWallet {
  /// **Provider for making RPC calls**
  final EmbeddedEthereumWalletProvider provider;

  /// **Constructor**
  EmbeddedEthereumWallet({
    super.id,
    required super.address,
    super.chainId,
    super.recoveryMethod,
    required super.hdWalletIndex,
  })  : provider = RealEmbeddedEthereumWalletProvider(walletAddress: address),
        super(chainType: ChainType.ethereum);

  /// **Factory constructor to create `EmbeddedEthereumWallet` from JSON**
  factory EmbeddedEthereumWallet.fromJson(
    Map<String, dynamic> json,
  ) {
    return EmbeddedEthereumWallet(
      id: json['id'] as String?,
      address: json['address'] as String,
      chainId: json['chainId'] as String?,
      recoveryMethod: json['recoveryMethod'] as String?,
      hdWalletIndex: json['hdWalletIndex'] as int,
    );
  }
}
