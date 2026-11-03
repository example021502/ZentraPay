/// A card the user chose to keep after a card top-up. Only display details: the gateway token stays on
/// the server and the card number / CVV never reach ZentraPay at all.
class SavedCard {
  final String id;
  final String gateway;
  final String brand;
  final String cardType;
  final String last4;
  final String bank;
  final int? expMonth;
  final int? expYear;
  final bool isDefault;
  final bool expired;

  const SavedCard({
    required this.id,
    required this.gateway,
    required this.brand,
    required this.cardType,
    required this.last4,
    required this.bank,
    this.expMonth,
    this.expYear,
    this.isDefault = false,
    this.expired = false,
  });

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      id: (json['id'] ?? '').toString(),
      gateway: (json['gateway'] ?? '').toString(),
      brand: (json['brand'] ?? '').toString().trim(),
      cardType: (json['cardType'] ?? '').toString().trim(),
      last4: (json['last4'] ?? '').toString(),
      bank: (json['bank'] ?? '').toString().trim(),
      expMonth: (json['expMonth'] as num?)?.toInt(),
      expYear: (json['expYear'] as num?)?.toInt(),
      isDefault: json['isDefault'] == true || json['default'] == true,
      expired: json['expired'] == true,
    );
  }

  /// "Visa" / "Card" - what to call the card when the gateway gave no brand.
  String get brandLabel {
    if (brand.isEmpty) return cardType.isEmpty ? 'Card' : _capital(cardType);
    return _capital(brand);
  }

  /// "Visa ••4242"
  String get label => '$brandLabel ••$last4';

  /// "09/28", or empty when the gateway did not report an expiry.
  String get expiry {
    if (expMonth == null || expYear == null) return '';
    final year = (expYear! % 100).toString().padLeft(2, '0');
    return '${expMonth.toString().padLeft(2, '0')}/$year';
  }

  static String _capital(String s) {
    final t = s.trim();
    return t.isEmpty ? t : t[0].toUpperCase() + t.substring(1).toLowerCase();
  }
}
