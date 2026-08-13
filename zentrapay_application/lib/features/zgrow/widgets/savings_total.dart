import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/repositories/zbanking_repository.dart';

/// Sum of savings account balances sharing the primary account's currency —
/// display-only aggregation, never sent back to the server.
class SavingsTotal {
  const SavingsTotal._();

  static double amount() {
    final accounts = SavingsRepository.instance.data;
    if (accounts == null || accounts.isEmpty) return 0;
    final currency = accounts.first.currencyCode;
    return accounts
        .where((a) => a.currencyCode == currency)
        .fold<double>(0, (sum, a) => sum + a.balance.toAmount());
  }

  static String _currencyCode() {
    final accounts = SavingsRepository.instance.data;
    return (accounts == null || accounts.isEmpty)
        ? "GHS"
        : accounts.first.currencyCode;
  }

  static String label() {
    final accounts = SavingsRepository.instance.data;
    if (accounts == null) {
      return SavingsRepository.instance.isLoading ? "…" : "GHS 0.00";
    }
    if (accounts.isEmpty) return "GHS 0.00";
    return formatMoney(
      amount().toStringAsFixed(2),
      symbol: "${_currencyCode()} ",
    );
  }
}
