import 'package:flutter/foundation.dart';

/// Unified result returned by [PaymentsService.createCustomerWithFailover].
///
/// Both Paystack and Flutterwave customer-creation responses are normalised
/// into this single shape so callers don't need to know which gateway
/// ultimately handled the request — except for [gateway], which the DEPLOYMENT
/// GUIDE says should be surfaced to the user "for transparency" on failover.
@immutable
class GatewayCustomerResult {
  /// Which gateway successfully created the customer.
  ///
  /// Values: `'paystack'` or `'flutterwave'`.
  final String gateway;

  /// The gateway-issued customer identifier (Paystack `code` or Flutterwave `id`).
  final String customerId;

  /// The customer's email.
  final String email;

  /// The customer's full display name (best-effort, may be empty).
  final String? displayName;

  /// The customer's phone number, if returned by the gateway.
  final String? phone;

  const GatewayCustomerResult({
    required this.gateway,
    required this.customerId,
    required this.email,
    this.displayName,
    this.phone,
  });

  /// Human-readable label for the gateway, used in toasts/UI.
  String get gatewayLabel {
    switch (gateway) {
      case 'paystack':
        return 'Paystack';
      case 'flutterwave':
        return 'Flutterwave';
      default:
        return gateway;
    }
  }
}
