import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/payments/milestones_screen.dart';
import 'package:zentrapay_application/features/zbanking/pay_loans_screen.dart';
import 'package:zentrapay_application/features/wallet_topup/topup_screen.dart';
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
        // Comment: Using showModalBottomSheet with isScrollControlled to display the TopupScreen properly as an interactive modal overlay.
        Expanded(
          child: QuickActionButton(
            icon: Icons.add_circle_outline,
            label: "Top Up",
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled:
                  true, // Comment: Allows the sheet to scale dynamically with content and keyboard
              backgroundColor: Colors
                  .transparent, // Comment: Prevents default background override so custom container styles apply
              builder: (BuildContext context) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.gray50,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusXxl),
                    ),
                    border: Border.all(color: AppTheme.textBlack),
                  ),
                  // Comment: Restricts maximum height to 85% of screen to avoid full-screen stretching conflicts
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                    maxWidth: double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppTheme.spacingMd,
                      AppTheme.spacingLg,
                      AppTheme.spacingMd,
                      (AppTheme.spacingLg +
                          MediaQuery.of(context).viewInsets.bottom),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Comment: Title at the top of the modal
                        Text(
                          'Fund your zentrapay wallet',
                          style: AppTheme.headlineMedium,
                        ),
                        AppTheme.divider(context, AppTheme.gray500),
                        const SizedBox(height: AppTheme.spacingMd),
                        const TopupScreen(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
