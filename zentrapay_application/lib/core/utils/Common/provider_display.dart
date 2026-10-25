import 'package:flutter/material.dart';

/// Provider-directory display helpers shared by the home services grid and
/// the provider picker: category -> icon, and country code -> flag emoji.

/// Icon for a bill/service provider category.
///
/// Mirrors `Datatypes.ProviderCategory` on the backend — the category codes
/// (UTILITY, AIRTIME, TV_SUBSCRIPTION, ...) are the shared contract; unknown
/// codes fall back to the generic receipt icon so a new backend category can
/// never break the grid.
IconData providerCategoryIcon(String? categoryCode) {
  switch ((categoryCode ?? '').trim().toUpperCase()) {
    case 'UTILITY':
      return Icons.bolt_rounded; // Electricity & Water
    case 'AIRTIME':
      return Icons.phone_in_talk_rounded; // Airtime & Mobile Data
    case 'TV_SUBSCRIPTION':
      return Icons.tv_rounded; // TV Subscription
    case 'INTERNET':
      return Icons.wifi_rounded; // Internet & Broadband
    case 'INSURANCE':
      return Icons.health_and_safety_rounded; // Insurance
    case 'GOVERNMENT':
      return Icons.account_balance_rounded; // Government Services
    case 'TRANSPORT':
      return Icons.directions_bus_rounded; // Transport & Toll
    case 'EDUCATION':
      return Icons.school_rounded; // Education & School Fees
    case 'HEALTH':
      return Icons.medical_services_rounded; // Health & Medical
    case 'ENTERTAINMENT':
      return Icons.confirmation_number_rounded; // Entertainment & Ticketing
    default:
      return Icons.receipt_long_rounded; // OTHERS / unknown
  }
}

/// Flag emoji for an ISO country code ("GH" -> 🇬🇭) built from the regional-
/// indicator symbols. ISO-3 codes ("GHA") work too — the first two letters
/// map to the same flag wherever the ISO-3 shares the ISO-2 prefix.
/// Returns an empty string for unusable input so callers can fall through
/// to the category icon.
String countryCodeToFlag(String? countryCode) {
  final String code = (countryCode ?? '').trim().toUpperCase();
  if (code.length < 2) return '';
  final int a = code.codeUnitAt(0);
  final int b = code.codeUnitAt(1);
  final bool bothLetters =
      a >= 0x41 && a <= 0x5A && b >= 0x41 && b <= 0x5A; // 'A'..'Z'
  if (!bothLetters) return '';
  return String.fromCharCode(0x1F1E6 + (a - 0x41)) +
      String.fromCharCode(0x1F1E6 + (b - 0x41));
}
