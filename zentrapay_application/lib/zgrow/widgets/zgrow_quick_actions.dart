import 'package:flutter/material.dart';

class ZGrowQuickActions extends StatelessWidget {
  const ZGrowQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 20,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _item(Icons.security, "Emergence\nFund"),
        _item(Icons.payments_outlined, "Pay-Loans"),
        _item(
          Icons.trending_up,
          "Z-Invest",
          onTap: () => Navigator.pushNamed(context, '/zinvest'),
        ),
      ],
    );
  }

  Widget _item(IconData icon, String label, {VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[200],
              child: Icon(icon, color: Colors.black87, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
}
