import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/bill_service_provider.dart';
import 'package:zentrapay_application/core/repositories/cards_repository.dart';
import 'package:zentrapay_application/core/repositories/providers_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/home/HomePayments/pay.dart';
import 'package:zentrapay_application/features/home/provider_picker_sheet.dart';
import 'package:zentrapay_application/features/home/receive_sheet.dart';
import 'package:zentrapay_application/features/zvoice/zvoice_screen.dart';
import 'package:zentrapay_application/main.dart';

import 'history.dart';

/// Home Quick Actions Widget
///
/// Provides quick access to main features from home screen
/// - NFC Pay: Contactless payments
/// - Pay: Send money to contacts
/// - To Bank: External bank transfers
/// - History: Transaction history
///
/// @description Quick action buttons for home screen
/// @version 1.0.0
/// @author ZentraPay Team

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

  /// Handle NFC Pay action
  /// @description Initiates NFC payment flow
  void _onNFCAction(BuildContext context) {
    // No NFC hardware integration in this pass — nothing to wire to a
    // backend endpoint yet.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('NFC Pay - Coming Soon!'),
        backgroundColor: AppColors.main,
      ),
    );
  }

  /// Handle Receive action — shows the user's zentag, QR receive link, and
  /// linked bank accounts (ReceiveSheet), so a sender can identify how to
  /// pay this user. This used to trigger a Paystack wallet-funding flow;
  /// that flow is preserved below (_showAccessCodeDialog) for reuse from
  /// the wallet balance card's "+" (fund wallet) action instead, since that's
  /// a different action ("add money from my own card/bank") than "receive
  /// money from someone else".
  void _onReceiveAction(BuildContext context) {
    ReceiveSheet.show(context);
  }

  // ignore: unused_element
  void _showAccessCodeDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Funding'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reference: ${data['reference'] ?? '-'}'),
            const SizedBox(height: 8),
            Text(
              'Authorization URL:\n${data['authorizationUrl'] ?? '-'}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            const Text(
              'Complete the payment via the link above to fund your wallet.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show History bottom sheet
  /// @description Displays transaction history
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuickActionButton(
          icon: Icons.nfc,
          label: "NFC Pay",
          onTap: () => _onNFCAction(context),
        ),
        QuickActionButton(
          icon: Icons.arrow_upward_outlined,
          label: "Send",
          onTap: () => _onPayAction(context),
        ),
        QuickActionButton(
          icon: Icons.arrow_downward_outlined,
          label: "Receive",
          onTap: () => _onReceiveAction(context),
        ),
        QuickActionButton(
          icon: Icons.history,
          label: "History",
          onTap: () => _onHistoryAction(context),
        ),
        QuickActionButton(
          icon: Icons.more_horiz,
          label: "More",
          onTap: () => _onMoreAction(context),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _loadBillProviders() async {
    final providers =
        await BillProvidersRepository.instance.ensureLoaded() ??
        <BillProvider>[];
    return providers
        .map(
          (p) => {
            'providerId': p.providerId,
            'billerName': p.billerName,
            'logoUrl': p.logoUrl ?? '',
            'category': p.categoryCode,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _loadServiceProviders() async {
    final providers =
        await ServiceProvidersRepository.instance.ensureLoaded() ??
        <ServiceProvider>[];
    return providers
        .map(
          (p) => {
            'providerId': p.providerId,
            'providerName': p.providerName,
            'logoUrl': p.logoUrl ?? '',
            'category': p.categoryCode,
          },
        )
        .toList();
  }

  late final List<Map<String, dynamic>> options = [
    {
      "text": "New Bill Providers",
      "title": "Bill Providers",
      "loader": _loadBillProviders,
      "nameKey": "billerName",
      "icon": Icons.receipt_long,
      "id": "Bill Providers",
    },
    {
      "text": "New Service Providers",
      "title": "Service Providers",
      "loader": _loadServiceProviders,
      "nameKey": "providerName",
      "icon": Icons.store,
      "id": "Service Providers",
    },
    {
      "text": "New Card",
      "title": "New Card",
      "icon": Icons.credit_card,
      "id": "Cards",
    },
    {"text": "ZVoice AI", "icon": Icons.mic, "id": "ZVoice AI"},
  ];

  /// Shows the "More" popup: New Bill Provider / New Service Provider (each
  /// opening a searchable catalog sourced from the real backend), New Card
  /// (creates a virtual card via [CardsRepository]), ZVoice AI, and
  /// Settings & Security. This absorbed what used to be the main Scaffold
  /// AppBar's separate "More" menu (ZVoice AI + Secure) — that appbar entry
  /// point is gone now, this is the one place to reach all of it.
  void _onMoreAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          // Wrapped in Column with shrinkWrap ListView
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ListView.builder syntax for a dynamic list
              ListView.builder(
                // Make the list wrap its content height to prevent layout crashes
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // 1. Total number of items in the list (Required)
                itemCount: options.length,

                // 2. Builder callback that creates a widget for each index (Required)
                itemBuilder: (BuildContext context, int i) {
                  final option = options[i];
                  // Return the widget for the specific item at this index
                  return ListTile(
                    leading: Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(option["icon"], color: AppColors.secondary),
                      ),
                    ),
                    title: Text(option["text"]),
                    onTap: () {
                      Navigator.pop(context);
                      switch (option["id"]) {
                        case "Cards":
                          _createVirtualCard(context);
                          return;
                        case "ZVoice AI":
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ZVoiceScreen(),
                            ),
                          );
                          return;
                      }
                      ProviderPickerSheet.show(
                        context,
                        title: option["title"],
                        loader: option["loader"]!,
                        nameKey: option["nameKey"],
                        id: option["id"],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createVirtualCard(BuildContext context) async {
    final brand = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Text("Choose Card Brand", style: AppTheme.headlineSmall),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text("Visa"),
              onTap: () => Navigator.pop(context, "VISA"),
            ),
            ListTile(
              leading: const Icon(Icons.credit_card),
              title: const Text("Mastercard"),
              onTap: () => Navigator.pop(context, "MASTERCARD"),
            ),
          ],
        ),
      ),
    );
    if (brand == null || !context.mounted) return;

    try {
      await CardsRepository.instance.createVirtualCard(brand);
      if (context.mounted) {
        ZentraNotifier.success("Success", "Virtual card created!");
      }
    } catch (e) {
      if (context.mounted) {
        ZentraNotifier.error("Error", "Could not create card, try again.");
      }
    }
  }

  /// Show Pay bottom sheet
  /// @description Displays payment options
  void _onPayAction(BuildContext context) {
    showModalBottomSheet(
      // 5. Fixed variable name to match the controller defined in initState
      transitionAnimationController: _customAnimationController,
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
              const SizedBox(height: AppTheme.spacingSm),
              const Expanded(child: PaySectionMain()),
            ],
          ),
        );
      },
    );
  }
}
