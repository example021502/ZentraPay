/// Represents a JSON-RPC response from the Ethereum wallet provider.
class EthereumRpcResponse {
  final String method;
  final String data;

  EthereumRpcResponse({required this.method, required this.data});

  /// Convert response to JSON
  Map<String, dynamic> toJson() => {
        "method": method,
        "data": data,
      };

  /// Create `EthereumRpcResponse` from JSON
  factory EthereumRpcResponse.fromJson(Map<String, dynamic> json) {
    return EthereumRpcResponse(
      method: json["method"] as String,
      data: json["data"] as String,
    );
  }
}
