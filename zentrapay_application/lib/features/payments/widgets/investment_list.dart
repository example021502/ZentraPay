import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/zinvest.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Renders the real portfolio from [InvestmentsRepository] — one row per
/// [Investment] with a Sell action for still-active positions. Replaces the
/// old hardcoded three-fund list that never touched the network.
class InvestmentList extends StatefulWidget {
  final List<Investment> investments;
  final Future<void> Function(String investmentId) onSell;

  const InvestmentList({
    super.key,
    required this.investments,
    required this.onSell,
  });

  @override
  State<InvestmentList> createState() => _InvestmentListState();
}

class _InvestmentListState extends State<InvestmentList> {
  String? _sellingId;

  bool _isActive(String status) => status.toUpperCase() == 'ACTIVE';

  Future<void> _confirmSell(Investment investment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sell investment?"),
        content: Text(
          "Sell your position in ${investment.name}"
          "${investment.symbol != null ? ' (${investment.symbol})' : ''}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sell"),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _sellingId = investment.investmentId);
    try {
      await widget.onSell(investment.investmentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to sell: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _sellingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.investments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text(
          "No investments yet.",
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
      );
    }

    return Column(
      children: widget.investments.map((investment) {
        final buyAmount = investment.buyPrice.toAmount();
        final currentAmount = investment.currentPrice.toAmount();
        final gainLoss = currentAmount - buyAmount;
        final isUp = gainLoss >= 0;
        final active = _isActive(investment.status);
        final selling = _sellingId == investment.investmentId;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: AppTheme.zinvestColor.withAlpha(25),
              child: Icon(
                Icons.show_chart,
                size: 18,
                color: AppTheme.zinvestColor,
              ),
            ),
            title: Text(
              investment.symbol != null
                  ? "${investment.name} (${investment.symbol})"
                  : investment.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              "Qty ${investment.quantity} · "
              "${formatMoney(investment.buyPrice)} -> "
              "${formatMoney(investment.currentPrice)} "
              "${investment.currencyCode} · ${investment.status}",
              style: TextStyle(
                color: isUp ? AppTheme.successGreen : AppTheme.errorRed,
                fontSize: 12,
              ),
            ),
            trailing: active
                ? (selling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: () => _confirmSell(investment),
                          child: const Text("Sell"),
                        ))
                : Text(
                    investment.status,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
          ),
        );
      }).toList(),
    );
  }
}
