import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class ZGrowRewards extends StatelessWidget {
  const ZGrowRewards({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text("Rewards", style: AppStyles.header),
        const SizedBox(height: 5),
        _item(Icons.stars, "Cash-back & Savings habits"),
        _item(Icons.emoji_events_outlined, "Badges for saving habits"),
        _item(Icons.card_giftcard, "Accessing rewards"),
        _item(Icons.percent, "Micro-loans discounts"),
      ],
    );
  }

  Widget _item(IconData icon, String label) => ListTile(
    contentPadding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
    leading: Icon(icon, color: AppColors.main, size: 20),
    title: Text(label, style: const TextStyle(fontSize: 14)),
  );
}
