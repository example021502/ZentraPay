import 'package:flutter/material.dart';
import 'package:zentrapay_application/home_wallet/widgets/pay.dart';
import 'package:zentrapay_application/main.dart';

import 'history.dart';

/**
 * Home Quick Actions Widget
 *
 * Provides quick access to main features from home screen
 * - NFC Pay: Contactless payments
 * - Pay: Send money to contacts
 * - To Bank: External bank transfers
 * - History: Transaction history
 *
 * @description Quick action buttons for home screen
 * @version 1.0.0
 * @author ZentraPay Team
 */

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  /**
   * Handle NFC Pay action
   * @description Initiates NFC payment flow
   */
  void _onNFCAction(BuildContext context) {
    // TODO: Implement NFC payment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('NFC Pay - Coming Soon!'),
        backgroundColor: AppColors.main,
      ),
    );
  }

  /**
   * Handle To Bank action
   * @description Navigates to external payment screen
   */
  void _onBankAction(BuildContext context) {
    // Navigate to external payment screen
    Navigator.pushNamed(context, '/external_payment');
  }

  /**
   * Show History bottom sheet
   * @description Displays transaction history
   */
  void _onHistoryAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.90,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              const Expanded(child: PaymentHistory()),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final horizontalPadding = isTablet ? 40.0 : 15.0;
    final iconSize = isTablet ? 28.0 : 22.0;
    final avatarRadius = isTablet ? 32.0 : 26.0;
    final fontSize = isTablet ? 14.0 : 12.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 10,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 5,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.lightGrey.withAlpha(50)),
              ),
            ),
            child: Text("Quick Actions", style: AppStyles.header),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 20,
            children: [
              _action(
                context,
                Icons.nfc,
                "NFC Pay",
                () => _onNFCAction(context),
                iconSize: iconSize,
                avatarRadius: avatarRadius,
                fontSize: fontSize,
              ),
              _action(
                context,
                Icons.send,
                "Pay",
                () => _onPayAction(context),
                iconSize: iconSize,
                avatarRadius: avatarRadius,
                fontSize: fontSize,
              ),
              _action(
                context,
                Icons.account_balance,
                "Deposit",
                () => _onBankAction(context),
                iconSize: iconSize,
                avatarRadius: avatarRadius,
                fontSize: fontSize,
              ),
              _action(
                context,
                Icons.history,
                "History",
                () => _onHistoryAction(context),
                iconSize: iconSize,
                avatarRadius: avatarRadius,
                fontSize: fontSize,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /**
   * Show Pay bottom sheet
   * @description Displays payment options
   */
  void _onPayAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.96,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4.5,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              const Expanded(child: PaySectionMain()),
            ],
          ),
        );
      },
    );
  }

  /**
   * Build action button widget
   * @param {BuildContext} context - Build context
   * @param {IconData} icon - Icon to display
   * @param {String} label - Button label
   * @param {VoidCallback} onTapping - Callback function
   */
  Widget _action(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTapping, {
    double iconSize = 16,
    double avatarRadius = 20,
    double fontSize = 12,
  }) => GestureDetector(
    onTap: onTapping,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: avatarRadius,
          backgroundColor: AppColors.lightGrey.withAlpha(50),
          child: Icon(icon, color: AppColors.textBlack, size: iconSize),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w500,
            height: 1.2,
            color: AppColors.secondary,
          ),
        ),
      ],
    ),
  );
}
