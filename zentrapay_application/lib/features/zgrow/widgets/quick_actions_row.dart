import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/payments/milestones_screen.dart';
import 'package:zentrapay_application/features/zbanking/pay_loans_screen.dart';
import 'package:zentrapay_application/features/wallet/topup_screen.dart';
import 'package:zentrapay_application/features/zgrow/emergency/emergency_vault_screen.dart';

/// Emergency Vault / Pay Loans / Save Goal / Z-Invest row. Z-Invest is switched
/// off for now: tapping it only shows a "not available" notice and never opens
/// the section.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    // Same buttons, spacing and alignment as the Home quick actions.
    return Row(
      verticalDirection: VerticalDirection.down,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: QuickActionButton(
            icon: Icons.health_and_safety_outlined,
            label: "Emergency",
            onTap: () => _open(context, const EmergencyVaultScreen()),
          ),
        ),
        Expanded(
          child: QuickActionButton(
            icon: Icons.payments_outlined,
            label: "Pay Loans",
            onTap: () => _open(context, const PayLoansScreen()),
          ),
        ),
        Expanded(
          child: QuickActionButton(
            icon: Icons.flag_outlined,
            label: "Save Goal",
            onTap: () => _open(context, const MilestonesScreen()),
          ),
        ),
        Expanded(
          child: QuickActionButton(
            icon: Icons.trending_up,
            label: "Z-Invest",
            onTap: () => ZentraNotifier.notice(
              "ZInvest is not available at the moment",
              icon: Icons.lock_clock_outlined,
            ),
          ),
        ),
        Expanded(
          child: QuickActionButton(
            icon: Icons.add_circle_outline,
            label: "Top Up",
            onTap: () => _open(context, const TopupScreen()),
          ),
        ),
      ],
    );
  }
}
