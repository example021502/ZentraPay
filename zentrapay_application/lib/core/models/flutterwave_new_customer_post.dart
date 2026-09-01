import 'package:flutter/foundation.dart';

/// Request body for Flutterwave's "Create Customer" endpoint
/// (POST /v3/customers on the Flutterwave API, proxied by the backend at
/// /api/payments/flutterwave/customer).
///
/// Constructed in the same style as [PaystackNewCustomerPost] — the only
/// differences are the field naming (Flutterwave uses `meta` rather than
/// `metadata`, otherwise the shapes are identical) so the two classes are
/// interchangeable in the failover layer.
@immutable
class FlutterwaveNewCustomerPost {
  /// The customer's email address — required by Flutterwave.
  final String email;

  /// Customer's first name (Flutterwave: first_name).
  final String? firstName;

  /// Customer's last name (Flutterwave: last_name).
  final String? lastName;

  /// Customer's phone number (Flutterwave: phone).
  final String? phone;

  /// Optional meta blob — Flutterwave's equivalent of Paystack's metadata.
  final Map<String, dynamic>? meta;

  const FlutterwaveNewCustomerPost({
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.meta,
  });

  /// Serialises to the Flutterwave API's expected JSON envelope (snake_case keys).
  Map<String, dynamic> toJson() => {
    'email': email,
    if (firstName != null) 'first_name': firstName,
    if (lastName != null) 'last_name': lastName,
    if (phone != null) 'phone': phone,
    if (meta != null) 'meta': meta,
  };
}

/// Response wrapper for Flutterwave's customer-creation endpoint.
///
/// The backend forwards Flutterwave's envelope and unwraps `data` for the
/// caller, so this parses the inner `data` object.
@immutable
class FlutterwaveCustomerResponse {
  /// The Flutterwave customer id.
  final String? id;

  /// The customer's email.
  final String email;

  /// The customer's first name.
  final String? firstName;

  /// The customer's last name.
  final String? lastName;

  /// The customer's phone number.
  final String? phone;

  const FlutterwaveCustomerResponse({
    this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  factory FlutterwaveCustomerResponse.fromJson(Map<String, dynamic> json) =>
      FlutterwaveCustomerResponse(
        id: json['id']?.toString(),
        email: json['email']?.toString() ?? '',
        firstName: json['first_name']?.toString(),
        lastName: json['last_name']?.toString(),
        phone: json['phone']?.toString(),
      );
}
