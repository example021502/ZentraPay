import 'dart:convert';

import 'package:privy_flutter/src/utils/json_serializable.dart';

/// Encapsulates API request details to be signed by the user's signing key.
///
/// The payload is canonicalized before signing to ensure consistent byte
/// representation. The resulting signature can be used as the
/// `privy-authorization-signature` HTTP header.
class WalletApiPayload implements JsonSerializable {
  /// Version of the payload format (currently only version 1 is supported).
  final int version;

  /// Full URL including protocol and domain (no trailing slash).
  /// Example: "https://auth.privy.io/api/v1/wallets/{wallet_id}/rpc"
  final String url;

  /// HTTP method (e.g., "GET", "POST", "PUT", "DELETE").
  final String method;

  /// Privy-specific headers (those prefixed with 'privy-').
  /// Must include "privy-app-id".
  final Map<String, String> headers;

  /// Request body as a JSON-serializable map.
  final Map<String, dynamic> body;

  const WalletApiPayload({
    required this.version,
    required this.url,
    required this.method,
    required this.headers,
    required this.body,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'url': url,
      'method': method,
      'headers': headers,
      'body': jsonEncode(body),
    };
  }
}
