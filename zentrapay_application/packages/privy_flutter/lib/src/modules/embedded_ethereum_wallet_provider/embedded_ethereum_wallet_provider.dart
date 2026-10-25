import 'package:privy_flutter/src/models/ethereum_rpc_request/ethereum_rpc_request.dart';
import 'package:privy_flutter/src/models/ethereum_rpc_response/ethereum_rpc_response.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Defines the Ethereum Wallet Provider interface for sending RPC requests.
abstract class EmbeddedEthereumWalletProvider {
  /// Sends an Ethereum JSON-RPC request
  Future<Result<EthereumRpcResponse>> request(EthereumRpcRequest request);
}
