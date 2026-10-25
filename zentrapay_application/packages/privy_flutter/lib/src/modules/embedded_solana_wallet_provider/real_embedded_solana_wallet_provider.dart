import 'dart:typed_data';

import 'package:privy_flutter/src/enums/solana_cluster.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/models/send_options/send_options.dart';
import 'package:privy_flutter/src/modules/embedded_solana_wallet_provider/embedded_solana_wallet_provider.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Implementation of the `EmbeddedSolanaWalletProvider` that interacts with the native platform.
class RealEmbeddedSolanaWalletProvider implements EmbeddedSolanaWalletProvider {
  /// Handles communication with the platform-specific code using method channels.
  final MethodChannelHandler _channelHandler = MethodChannelHandler();

  final String walletAddress; // Store wallet address internally

  /// **Constructor requires wallet address**
  RealEmbeddedSolanaWalletProvider({required this.walletAddress});

  /// Signs a given message using the Solana embedded wallet.
  ///
  /// Returns a `Future<String>` representing the signature of the signed message.
  ///
  /// Throws an `Exception` if there is an error during the signing process.
  @override
  Future<Result<String>> signMessage(String message) async {
    LoggerService.debug(
        "Solana signMessage request. Wallet: $walletAddress, Message: $message");

    try {
      // Invoke the native method with the provided message as a parameter.
      final String? result = await _channelHandler.invokeMethod<String>(
        "solanaSignMessage",
        {"message": message, "walletAddress": walletAddress},
      );

      // If no response is received, return a failure Result.
      if (result == null) {
        LoggerService.error("No response from Solana wallet provider.");
        return const Failure(
            PrivyException("No response from wallet provider"));
      }

      LoggerService.debug("Solana message signed successfully. $result");
      return Success(result);
    } catch (e) {
      LoggerService.error("Failed to sign Solana message: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// Signs a Solana transaction using the Solana embedded wallet.
  ///
  /// Returns a `Future<String>` representing the signed transaction as a Base64 encoded string.
  ///
  /// Throws an `Exception` if there is an error during the signing process.
  @override
  Future<Result<String>> signTransaction(Uint8List transaction) async {
    LoggerService.debug(
        "Solana signTransaction request. Wallet: $walletAddress, Transaction size: ${transaction.length} bytes");

    try {
      // Invoke the native method with the provided transaction as a parameter.
      final String? result = await _channelHandler.invokeMethod<String>(
        "solanaSignTransaction",
        {"transaction": transaction, "walletAddress": walletAddress},
      );

      // If no response is received, return a failure Result.
      if (result == null) {
        LoggerService.error("No response from Solana wallet provider.");
        return const Failure(
            PrivyException("No response from wallet provider"));
      }

      LoggerService.debug("Solana transaction signed successfully.");
      return Success(result);
    } catch (e) {
      LoggerService.error("Failed to sign Solana transaction: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// Signs and sends a Solana transaction using the Solana embedded wallet.
  ///
  /// Returns a `Future<String>` representing the transaction signature.
  ///
  /// Throws an `Exception` if there is an error during the process.
  @override
  Future<Result<String>> signAndSendTransaction({
    required Uint8List transaction,
    SolanaCluster? cluster,
    String? rpcUrl,
    SendOptions? sendOptions,
  }) async {
    LoggerService.debug(
        "Solana signAndSendTransaction request. Wallet: $walletAddress, Transaction size: ${transaction.length} bytes${cluster != null ? ', Cluster: ${cluster.name}' : ''}");

    try {
      final Map<String, dynamic> args = {
        "transaction": transaction,
        "walletAddress": walletAddress,
        if (cluster != null) "cluster": cluster.name,
        if (rpcUrl != null) "rpcUrl": rpcUrl,
        if (sendOptions != null) "sendOptions": sendOptions.toJson(),
      };

      // Invoke the native method
      final String? result = await _channelHandler.invokeMethod<String>(
        "solanaSignAndSendTransaction",
        args,
      );

      // If no response is received, return a failure Result.
      if (result == null) {
        LoggerService.error("No response from Solana wallet provider.");
        return const Failure(
            PrivyException("No response from wallet provider"));
      }

      LoggerService.debug(
          "Solana transaction signed and sent successfully. Signature: $result");
      return Success(result);
    } catch (e) {
      LoggerService.error("Failed to sign and send Solana transaction: $e");
      return Failure(e.convertToPrivyException());
    }
  }
}
