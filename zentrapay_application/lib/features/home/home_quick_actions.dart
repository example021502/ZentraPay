import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/utils/Common/EnterAmount.dart';
import 'package:zentrapay_application/features/home/pay.dart';
import 'package:zentrapay_application/main.dart';

import 'package:zentrapay_application/features/home/api_home_wallet_services.dart';
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

class HomeQuickActions extends StatefulWidget {
  const HomeQuickActions({super.key});

  @override
  State<HomeQuickActions> createState() => _HomeQuickActionsState();
}

// 1. Added TickerProviderStateMixin to allow 'this' to be used as vsync
class _HomeQuickActionsState extends State<HomeQuickActions>
    with TickerProviderStateMixin {
  late AnimationController _customAnimationController;

  @override
  void initState() {
    super.initState();

    // 2. Initialize using the BottomSheet helper to avoid layout conflicts
    _customAnimationController = BottomSheet.createAnimationController(this);

    // Customize the entry and exit durations
    _customAnimationController.duration = const Duration(
      milliseconds: 1000,
    ); // Entrance speed
    _customAnimationController.reverseDuration = const Duration(
      milliseconds: 600,
    ); // Exit speed
  }

  @override
  void dispose() {
    // 3. Clean up the controller when the widget is disposed to prevent memory leaks
    _customAnimationController.dispose();
    super.dispose();
  }

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
  void _onReceiveAction(BuildContext context) async {
    final Map<String, dynamic>? amount = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => EnterAmount(recipient: ''),
    );
    final response = await getAccessCode(amount!);

    //THIS IS FOR SENDING TO BANK =========================
    // Navigator.pushNamed(context, '/external_payment');
  }

  /**
   * Show History bottom sheet
   * @description Displays transaction history
   */
  void _onHistoryAction(BuildContext context) {
    showModalBottomSheet(
      // 4. Added custom animation controller here
      transitionAnimationController: _customAnimationController,
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
          const SizedBox(height: 6),
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
                "Send",
                () => _onPayAction(context),
                iconSize: iconSize,
                avatarRadius: avatarRadius,
                fontSize: fontSize,
              ),
              _action(
                context,
                Icons.account_balance,
                "Receive",
                () => _onReceiveAction(context),
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
          SizedBox(height: 6),
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
      // 5. Fixed variable name to match the controller defined in initState
      transitionAnimationController: _customAnimationController,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.5,
            maxHeight: MediaQuery.of(context).size.height * 0.96,
          ),
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
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: AppColors.textBlack,
          ),
        ),
      ],
    ),
  );
}
