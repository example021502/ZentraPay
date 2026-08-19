import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/placeholder_screen.dart';
import 'package:zentrapay_application/features/zinvest/zinvest_screen.dart';
import 'package:zentrapay_application/main.dart';

import '../../../core/theme/common_widgets.dart';

/// Emergency Fund / Pay-Loans / Z-Invest row. Z-Invest opens the real
/// ZInvestScreen; the other two don't have dedicated pages yet, so they
/// open a labeled PlaceholderScreen instead of a silent no-op.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        _QuickActionButton(
          icon: Icons.arrow_downward_outlined,
          label: "Save Now",
          onTap: () {
            showComingSoon(context, "This feature");
          },
        ),
        _QuickActionButton(
          icon: Icons.verified_user_outlined,
          label: "Emergence\nFund",
          onTap: () =>
              _open(context, const PlaceholderScreen(title: "Emergency Fund")),
        ),
        _QuickActionButton(
          icon: Icons.account_balance_wallet_outlined,
          label: "Pay-Loans",
          onTap: () =>
              _open(context, const PlaceholderScreen(title: "Pay Loans")),
        ),
        _QuickActionButton(
          icon: Icons.trending_up,
          label: "Z-Invest",
          onTap: () => _open(context, const ZInvestScreen()),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.textBlack,
              size: 22,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, style: AppTheme.bodySmall),
        ],
      ),
    );
  }
}
