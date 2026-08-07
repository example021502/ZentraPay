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

class AppCurrency {
  final String currencyCode;
  final String currencyName;
  final String symbol;
  final bool isCrypto;
  final int decimalPlaces;

  AppCurrency({
    required this.currencyCode,
    required this.currencyName,
    required this.symbol,
    required this.isCrypto,
    required this.decimalPlaces,
  });

  factory AppCurrency.fromJson(Map<String, dynamic> json) => AppCurrency(
    currencyCode: json['currencyCode'] ?? '',
    currencyName: json['currencyName'] ?? '',
    symbol: json['countryIsoCode'] ?? '',
    isCrypto: json['isCrypto'] ?? false,
    decimalPlaces: json['decimalPlaces'] ?? 2,
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
