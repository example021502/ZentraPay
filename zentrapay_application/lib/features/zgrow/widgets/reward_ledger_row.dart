import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

class RewardLedgerRow extends StatelessWidget {
  const RewardLedgerRow({super.key, required this.entry});

  final PointsLedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    final positive = entry.points >= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              entry.reason,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "${positive ? '+' : ''}${entry.points} pts",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: positive ? AppTheme.zgrowColor : AppTheme.errorRed,
            ),
          ),
        ],
      ),
    );
  }
}
