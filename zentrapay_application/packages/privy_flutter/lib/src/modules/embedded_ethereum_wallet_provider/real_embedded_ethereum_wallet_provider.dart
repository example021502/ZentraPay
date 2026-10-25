import 'dart:async';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/models/ethereum_rpc_request/ethereum_rpc_request.dart';
import 'package:privy_flutter/src/models/ethereum_rpc_response/ethereum_rpc_response.dart';
import 'package:privy_flutter/src/modules/embedded_ethereum_wallet_provider/embedded_ethereum_wallet_provider.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Implementation of `EthereumWalletProvider` that communicates via MethodChannel.
class RealEmbeddedEthereumWalletProvider
    implements EmbeddedEthereumWalletProvider {
  final MethodChannelHandler _channelHandler = MethodChannelHandler();

  final String walletAddress; // Store wallet address internally

  /// **Constructor requires wallet address**
  RealEmbeddedEthereumWalletProvider({required this.walletAddress});

  @override
  Future<Result<EthereumRpcResponse>> request(
      EthereumRpcRequest request) async {
    LoggerService.debug(
        "Ethereum RPC request received. Wallet: $walletAddress, Method: ${request.method}, Params: ${request.params}");

    // List of supported Ethereum RPC methods
    const Set<String> supportedMethods = {
      "eth_sign",
      "personal_sign",
      "secp256k1_sign",
      "eth_signTypedData_v4",
      "eth_signTransaction",
      "eth_sendTransaction",
    };

    // Check if the method is supported
    if (!supportedMethods.contains(request.method)) {
      LoggerService.error("Unsupported Ethereum RPC method: ${request.method}");
      return Failure(PrivyException("Unsupported method: ${request.method}"));
    }

    try {
      final Map<String, dynamic> requestPayload = {
        ...request.toJson(), // Convert existing request to JSON
        "walletAddress":
            walletAddress, // Inject wallet address into the request payload
      };

      LoggerService.debug(
          "Sending Ethereum RPC request via MethodChannel. Payload: $requestPayload");

      final Map<Object?, Object?>? result = await _channelHandler.invokeMethod(
        'ethSendRpcRequest',
        requestPayload, // Send the modified request including the wallet address
      );

      LoggerService.debug("Ethereum RPC response received: $result");

      final convertedResponse = safeCastToMap(result);

      return Success(EthereumRpcResponse.fromJson(convertedResponse));
    } catch (e) {
      LoggerService.error("Ethereum RPC request failed: $e");
      return Failure(e.convertToPrivyException());
    }
  }
}
