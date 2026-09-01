import 'package:flutter/foundation.dart';

/// Request body for Paystack's "Create Customer" endpoint
/// (POST /v1/customers on the Paystack API, proxied by the backend at
/// /api/payments/paystack/customer).
///
/// Mirrors Paystack's snake_case field names so it can be passed through
/// [PaymentsService.createPaystackCustomer] as-is.
@immutable
class PaystackNewCustomerPost {
  /// The customer's email address — required by Paystack.
  final String email;

  /// Customer's first name (Paystack: first_name).
  final String? firstName;

  /// Customer's last name (Paystack: last_name).
  final String? lastName;

  /// Customer's phone number (Paystack: phone).
  final String? phone;

  /// Optional metadata blob — Paystack stores this on the customer record
  /// and returns it on subsequent lookups.
  final Map<String, dynamic>? metadata;

  const PaystackNewCustomerPost({
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.metadata,
  });

  /// Serialises to the Paystack API's expected JSON envelope (snake_case keys).
  Map<String, dynamic> toJson() => {
    'email': email,
    if (firstName != null) 'first_name': firstName,
    if (lastName != null) 'last_name': lastName,
    if (phone != null) 'phone': phone,
    if (metadata != null) 'metadata': metadata,
  };
}

/// Response wrapper for Paystack's customer-creation endpoint.
///
/// The backend forwards Paystack's envelope and unwraps `data` for the
/// caller, so this parses the inner `data` object.
@immutable
class PaystackCustomerResponse {
  /// The numerical Paystack customer id.
  final int? id;

  /// The Paystack customer code (e.g. "CUS_xxxxxxxxxxxxxxxx").
  final String code;

  /// The customer's email.
  final String email;

  /// The customer's first name.
  final String? firstName;

  /// The customer's last name.
  final String? lastName;

  /// The customer's phone number.
  final String? phone;

  const PaystackCustomerResponse({
    this.id,
    required this.code,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
  });

  factory PaystackCustomerResponse.fromJson(Map<String, dynamic> json) =>
      PaystackCustomerResponse(
        id: json['id'] is int
            ? json['id'] as int
            : int.tryParse(json['id']?.toString() ?? ''),
        code: json['code']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        firstName: json['first_name']?.toString(),
        lastName: json['last_name']?.toString(),
        phone: json['phone']?.toString(),
      );
}
