/// Money amounts travel over the wire as decimal strings (the backend uses
/// BigDecimal end-to-end) so we never lose precision to floating point.
/// This only converts to [double] for display/sorting — never do financial
/// arithmetic on the result, only formatting.
extension MoneyParsing on String? {
  double toAmount() => double.tryParse(this ?? '') ?? 0.0;
}

String formatMoney(String amount, {String symbol = ''}) {
  // Comment: a sign carried by the source string ("+25.00"/"-25.00", the
  // transactions API's credit/debit convention) must land as the very
  // first character of the result — AmountText/TransactionListItem detect
  // credit vs. debit by checking startsWith('+') on this exact string, so
  // "GHS -25.00" (sign after the currency symbol) would silently defeat
  // that check. Plain unsigned amounts (the common case elsewhere in the
  // app) are unaffected — no sign is added unless the source explicitly had one.
  final isExplicitCredit = amount.trim().startsWith('+');
  final value = amount.toAmount();
  final isNegative = value < 0;
  final fixed = value.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  final sign = isExplicitCredit ? '+' : (isNegative ? '-' : '');
  return '$sign$symbol$whole.${parts[1]}';
}
