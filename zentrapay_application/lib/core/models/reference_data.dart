class AppCountry {
  final String countryCode;
  final String iso3Code;
  final String countryName;
  final String dialCode;
  final String defaultCurrencyCode;
  final String? region;

  AppCountry({
    required this.countryCode,
    required this.iso3Code,
    required this.countryName,
    required this.dialCode,
    required this.defaultCurrencyCode,
    this.region,
  });

  factory AppCountry.fromJson(Map<String, dynamic> json) => AppCountry(
    countryCode: json['countryCode'] ?? '',
    iso3Code: json['iso3Code'] ?? '',
    countryName: json['countryName'] ?? '',
    dialCode: json['dialCode'] ?? '',
    defaultCurrencyCode: json['defaultCurrencyCode'] ?? '',
    region: json['region'],
  );
}

/// A currency ZentraPay moves money in. There is no currencies table on the
/// backend: a currency is listed because at least one active country has it
/// as its `default_currency`, and [countryCodes] are those countries (XOF is
/// shared by several).
class AppCurrency {
  final String currencyCode;
  final String currencyName;
  final String symbol;
  final bool isCrypto;
  final int decimalPlaces;
  final List<String> countryCodes;

  AppCurrency({
    required this.currencyCode,
    required this.currencyName,
    required this.symbol,
    required this.isCrypto,
    required this.decimalPlaces,
    this.countryCodes = const [],
  });

  factory AppCurrency.fromJson(Map<String, dynamic> json) => AppCurrency(
    currencyCode: json['currencyCode'] ?? '',
    currencyName: json['currencyName'] ?? '',
    // Backend CurrencyDTO exposes `symbol` ("GH₵", "₦", ...) — the
    // old key `countryIsoCode` never existed in the reference endpoint.
    symbol: json['symbol'] ?? '',
    isCrypto: json['isCrypto'] ?? false,
    decimalPlaces: json['decimalPlaces'] ?? 2,
    countryCodes: ((json['countryCodes'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(),
  );
}

class ProviderCategory {
  final String categoryCode;
  final String categoryName;

  ProviderCategory({required this.categoryCode, required this.categoryName});

  factory ProviderCategory.fromJson(Map<String, dynamic> json) =>
      ProviderCategory(
        categoryCode: json['categoryCode'] ?? '',
        categoryName: json['categoryName'] ?? '',
      );
}

class PaymentChannel {
  final String channelCode;
  final String channelName;
  final String channelType;
  final String countryCode;
  final String gateway;

  PaymentChannel({
    required this.channelCode,
    required this.channelName,
    required this.channelType,
    required this.countryCode,
    required this.gateway,
  });

  factory PaymentChannel.fromJson(Map<String, dynamic> json) => PaymentChannel(
    channelCode: json['channelCode'] ?? '',
    channelName: json['channelName'] ?? '',
    channelType: json['channelType'] ?? 'BANK',
    countryCode: json['countryCode'] ?? '',
    gateway: json['gateway'] ?? '',
  );
}
