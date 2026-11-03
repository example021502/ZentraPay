import 'package:zentrapay_application/core/models/reference_data.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profile_data.dart';

/// Which currency a payment is made in.
///
/// There is no currencies table: every country carries a `default_currency`
/// (served as `defaultCurrencyCode` by `GET /api/reference/countries`), and the
/// backend only lets a user pay in the default currency of the country they
/// registered in. This looks that currency up so the screens can show it up
/// front instead of letting the user pick one the backend will refuse.
class PaymentCurrency {
  const PaymentCurrency._();

  /// The default currency of [countryCode], or '' when the country list does
  /// not have it (yet).
  static Future<String> ofCountry(String countryCode) async {
    final code = countryCode.trim().toUpperCase();
    if (code.isEmpty) return '';
    final countries = await CountriesRepository.instance.ensureLoaded();
    for (final country in countries ?? const <AppCountry>[]) {
      if (country.countryCode.toUpperCase() == code) {
        return country.defaultCurrencyCode.trim().toUpperCase();
      }
    }
    return '';
  }

  /// The currency the signed-in user pays in: the default currency of the
  /// country they are registered in. '' when it cannot be worked out (offline,
  /// profile not loaded) - the backend still enforces the rule either way.
  static Future<String> ofSender() async {
    try {
      final snapshot = await UserProfileRepository.instance.ensureLoaded();
      return await ofCountry(snapshot?.user.countryCode ?? '');
    } catch (_) {
      return '';
    }
  }
}
