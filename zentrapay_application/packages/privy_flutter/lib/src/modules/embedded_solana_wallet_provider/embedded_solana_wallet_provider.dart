import 'dart:typed_data';

import 'package:privy_flutter/src/enums/solana_cluster.dart';
import 'package:privy_flutter/src/models/send_options/send_options.dart';
import 'package:privy_flutter/src/utils/result.dart';

abstract class EmbeddedSolanaWalletProvider {
  /// Returns the Base64 encoded computed signature.
  Future<Result<String>> signMessage(String message);

  /// Signs a Solana transaction.
  ///
  /// [transaction] - The transaction bytes to sign.
  /// Returns the signed transaction as a Base64 encoded string.
  Future<Result<String>> signTransaction(Uint8List transaction);

  /// Signs and sends a Solana transaction.
  ///
  /// [transaction] - The transaction bytes to sign and send.
  /// [cluster] - Optional Solana cluster to use. If null, uses default cluster.
  /// [rpcUrl] - Optional custom RPC URL. If null, uses default for the cluster.
  /// [sendOptions] - Optional send options (skipPreflight, preflightCommitment, etc.).
  /// Returns the transaction signature.
  Future<Result<String>> signAndSendTransaction({
    required Uint8List transaction,
    SolanaCluster? cluster,
    String? rpcUrl,
    SendOptions? sendOptions,
  });
}
