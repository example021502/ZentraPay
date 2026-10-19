import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/placeholder_screen.dart';
import 'package:zentrapay_application/features/zinvest/zinvest_screen.dart';


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
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppTheme.spacingXl,
      // Expanded keeps the three fixed actions inside the available width on
      // narrow screens instead of overflowing the Row (the labels are wider
      // than the icon circles once the font is wide or the screen is small).
      children: [
        Expanded(
          child: _QuickActionButton(
            icon: Icons.verified_user_outlined,
            label: "Emergence",
            onTap: () =>
                _open(context, const PlaceholderScreen(title: "Emergency Fund")),
          ),
        ),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.account_balance_wallet_outlined,
            label: "Pay-Loans",
            onTap: () =>
                _open(context, const PlaceholderScreen(title: "Pay Loans")),
          ),
        ),
        Expanded(
          child: _QuickActionButton(
            icon: Icons.trending_up,
            label: "Z-Invest",
            onTap: () => _open(context, const ZInvestScreen()),
          ),
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
    // Mirrors home_services_grid's _buildItem: a tinted icon chip on top with
    // the label underneath in bodySmall. Kept inside Expanded (rather than a
    // fixed 76px tile like home's scrolling row) so the three actions share the
    // width on narrow screens instead of overflowing.
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Tinted rounded chip — matches home's transaction/provider chip
          // (secondaryNavy tint, secondaryNavy icon).
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryNavy.withAlpha(20),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(icon, color: AppTheme.secondaryNavy, size: 22),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textBlack),
          ),
        ],
      ),
    );
  }
}
