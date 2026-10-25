/// Represents a JSON-RPC request to the Ethereum wallet provider.
class EthereumRpcRequest {
  final String method;
  final List<dynamic> params;

  EthereumRpcRequest({required this.method, required this.params});

  /// Convert to JSON for sending via Method Channel
  Map<String, dynamic> toJson() => {
        "method": method,
        "params": params,
      };

  /// Create `EthereumRpcRequest` from JSON
  factory EthereumRpcRequest.fromJson(Map<String, dynamic> json) {
    return EthereumRpcRequest(
      method: json["method"] as String,
      params: json["params"] as List<dynamic>,
    );
  }

  /// Creates a personal_sign RPC request
  factory EthereumRpcRequest.personalSign(String message, String address) {
    return EthereumRpcRequest(
      method: "personal_sign",
      params: [message, address],
    );
  }

  /// Creates a secp256k1_sign RPC request
  factory EthereumRpcRequest.secp256k1Sign(String hash) {
    return EthereumRpcRequest(
      method: "secp256k1_sign",
      params: [hash],
    );
  }

  /// Creates an eth_sign RPC request
  factory EthereumRpcRequest.ethSign(String address, String message) {
    return EthereumRpcRequest(
      method: "eth_sign",
      params: [address, message],
    );
  }

  /// Creates an eth_signTypedData_v4 RPC request
  factory EthereumRpcRequest.ethSignTypedDataV4(
      String address, String typedDataJson) {
    return EthereumRpcRequest(
      method: "eth_signTypedData_v4",
      params: [address, typedDataJson],
    );
  }

  /// Creates an eth_signTransaction RPC request
  factory EthereumRpcRequest.ethSignTransaction(String transactionJson) {
    return EthereumRpcRequest(
      method: "eth_signTransaction",
      params: [transactionJson],
    );
  }

  /// Creates an eth_sendTransaction RPC request
  factory EthereumRpcRequest.ethSendTransaction(String transactionJson) {
    return EthereumRpcRequest(
      method: "eth_sendTransaction",
      params: [transactionJson],
    );
  }
}
