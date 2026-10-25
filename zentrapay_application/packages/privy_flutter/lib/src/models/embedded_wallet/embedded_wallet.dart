import 'package:privy_flutter/src/enums/chain_type.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/models/embedded_ethereum_wallet/embedded_ethereum_wallet.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:privy_flutter/src/models/signer_input/signer_input.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Represents a generic embedded wallet.
abstract class EmbeddedWallet {
  /// The wallet ID.
  final String? id;

  /// The wallet's address.
  final String address;

  /// The chain ID.
  final String? chainId;

  /// Recovery method type.
  final String? recoveryMethod;

  /// HD wallet index.
  final int hdWalletIndex;

  /// Chain type (Ethereum, Solana, etc.).
  final ChainType chainType;

  /// **Constructor**
  EmbeddedWallet({
    this.id,
    required this.address,
    this.chainId,
    this.recoveryMethod,
    required this.hdWalletIndex,
    required this.chainType,
  });

  /// **Factory constructor to create an `EmbeddedWallet` from JSON**
  factory EmbeddedWallet.fromJson(Map<String, dynamic> json) {
    final chainType = ChainType.fromJson(
        json['chainType'] as String); // Convert from string to enum

    switch (chainType) {
      case ChainType.ethereum:
        return EmbeddedEthereumWallet.fromJson(json);
      case ChainType.solana:
        return EmbeddedSolanaWallet.fromJson(json);
    }
  }

  /// Adds multiple signers to this wallet.
  ///
  /// Signers are key quorum IDs that will be allowed to transact on the wallet.
  /// This is only supported for TEE wallets.
  Future<Result<void>> addSigners(List<SignerInput> signers) async {
    final channelHandler = MethodChannelHandler();
    try {
      await channelHandler.invokeMethod('addSigners', {
        'walletAddress': address,
        'signers': signers.map((s) => s.toJson()).toList(),
      });
      return const Success(null);
    } catch (e) {
      return Failure(e.convertToPrivyException('Failed to add signers'));
    }
  }

  /// Convenience method to add a single signer to this wallet.
  Future<Result<void>> addSigner(SignerInput signer) => addSigners([signer]);

  /// Removes a specific signer from this wallet by key quorum ID.
  Future<Result<void>> removeSigner(String signerId) async {
    final channelHandler = MethodChannelHandler();
    try {
      await channelHandler.invokeMethod('removeSigner', {
        'walletAddress': address,
        'signerId': signerId,
      });
      return const Success(null);
    } catch (e) {
      return Failure(e.convertToPrivyException('Failed to remove signer'));
    }
  }

  /// Removes all additional signers from this wallet.
  Future<Result<void>> removeAllSigners() async {
    final channelHandler = MethodChannelHandler();
    try {
      await channelHandler.invokeMethod('removeAllSigners', {
        'walletAddress': address,
      });
      return const Success(null);
    } catch (e) {
      return Failure(e.convertToPrivyException('Failed to remove all signers'));
    }
  }

  /// **Convert `EmbeddedWallet` to JSON**
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'chainId': chainId,
      'recoveryMethod': recoveryMethod,
      'hdWalletIndex': hdWalletIndex,
      'chainType': chainType.toJson(),
    };
  }
}
