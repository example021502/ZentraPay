/// How many digits a bank account number, or a mobile-money number, may have.
///
/// Used by the "send to bank" / "send to mobile money" sheet to stop a number
/// being typed that no bank in that country would ever issue, before the
/// payment provider is even asked. Countries not listed fall back to
/// [AccountNumberRule.fallbackBank].
class AccountNumberRule {
  final int min;
  final int max;

  const AccountNumberRule(this.min, this.max);

  /// Bank account numbers by ISO country code. Banks inside one country do not
  /// all use the same length, so several are a range rather than one value.
  static const Map<String, AccountNumberRule> _bank = {
    'GH': AccountNumberRule(10, 16),
    'NG': AccountNumberRule(10, 10), // NUBAN
    'KE': AccountNumberRule(10, 14),
    'UG': AccountNumberRule(10, 14),
    'TZ': AccountNumberRule(10, 14),
    'RW': AccountNumberRule(9, 16),
    'ZA': AccountNumberRule(9, 11),
    'ZM': AccountNumberRule(10, 13),
    'ZW': AccountNumberRule(10, 14),
    'MW': AccountNumberRule(7, 13),
    'BW': AccountNumberRule(8, 12),
    'NA': AccountNumberRule(8, 12),
    'ET': AccountNumberRule(10, 16),
    'EG': AccountNumberRule(10, 20),
    'MA': AccountNumberRule(16, 24),
    'SN': AccountNumberRule(10, 24),
    'CI': AccountNumberRule(10, 24),
    'CM': AccountNumberRule(10, 24),
    'BF': AccountNumberRule(10, 24),
    'ML': AccountNumberRule(10, 24),
    'BJ': AccountNumberRule(10, 24),
    'TG': AccountNumberRule(10, 24),
  };

  static const AccountNumberRule fallbackBank = AccountNumberRule(8, 20);

  /// A phone number with or without its country code.
  static const AccountNumberRule mobileMoney = AccountNumberRule(9, 15);

  static AccountNumberRule forBank(String countryCode) =>
      _bank[countryCode.trim().toUpperCase()] ?? fallbackBank;

  bool get isExact => min == max;

  /// "10 digits" or "10 to 16 digits".
  String get label => isExact ? '$min digits' : '$min to $max digits';

  /// Null when [digits] (digits only) is an acceptable length, else a message.
  String? validate(String digits, {String noun = 'account number'}) {
    if (digits.isEmpty) return 'Enter the $noun';
    if (digits.length < min) {
      return 'A $noun has $label - you entered ${digits.length}';
    }
    if (digits.length > max) {
      return 'A $noun has at most $max digits';
    }
    return null;
  }
}
