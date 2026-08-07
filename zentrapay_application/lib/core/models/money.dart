/// Money amounts travel over the wire as decimal strings (the backend uses
/// BigDecimal end-to-end) so we never lose precision to floating point.
/// This only converts to [double] for display/sorting — never do financial
/// arithmetic on the result, only formatting.
extension MoneyParsing on String? {
  double toAmount() => double.tryParse(this ?? '') ?? 0.0;
}

String formatMoney(String amount, {String symbol = ''}) {
  final value = amount.toAmount();
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ',',
  );
  return '$symbol$whole.${parts[1]}';
}
