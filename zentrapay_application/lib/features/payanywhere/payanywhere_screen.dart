import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/home/HomePayments/qr_scan_screen.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/make_payment.dart';
import 'package:zentrapay_application/features/home/history.dart';
import 'package:zentrapay_application/features/home/receive_sheet.dart';

/// Pay Anywhere - scan a ZentraPay QR code to pay, show your own QR to get paid,
/// send money, and see your payment history. Every action opens the same flow the
/// Home screen uses, so there is one way to pay and one history.
class PayAnywhereScreen extends StatefulWidget {
  const PayAnywhereScreen({super.key});

  @override
  State<PayAnywhereScreen> createState() => _PayAnywhereScreenState();
}

class _PayAnywhereScreenState extends State<PayAnywhereScreen> {
  final PaymentController _payment = PaymentController();
  bool _payInFlight = false;

  // Scan the receiver's QR code, then the shared Enter Amount -> PIN -> pay flow
  Future<void> _scanAndPay() async {
    if (_payInFlight) return;
    final ScannedPaymentTarget? target = await QrScanScreen.show(context);
    if (target == null || !mounted) return;

    await _payment.processPayment(
      context: context,
      recipientNameForUI: target.recipient['name'] as String,
      recipientMap: target.recipient,
      channelType: "INTERNAL",
      // Preselect the currency the scanned QR account is denominated in
      preferredCurrencyCode: target.receiveCurrency,
      onStateChanged: (bool inFlight) {
        if (mounted) setState(() => _payInFlight = inFlight);
      },
    );
  }

  void _showMyQr() => ReceiveSheet.show(context);

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text("Transaction History")),
          body: const PaymentHistory(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.payAnywhereColor,
      child: SingleChildScrollView(
        child: Column(
          children: [
            FeatureScreenHeader(
              title: "Pay Anywhere",
              subtitle: "Scan & pay with QR",
              backgroundColor: AppTheme.payAnywhereColor,
              icon: Icons.qr_code_2,
            ),
            FeatureScreenBody(
              children: [
                const SectionTitle(title: "Quick Actions"),
                const SizedBox(height: AppTheme.spacingMd),
                _buildQuickActions(context),
                const SizedBox(height: AppTheme.spacingXl),
                const SectionTitle(title: "Payment Features"),
                const SizedBox(height: AppTheme.spacingMd),
                ActionItemCard(
                  icon: Icons.qr_code_scanner,
                  title: "Scan & Pay with QR",
                  subtitle: "Pay anyone by scanning their ZentraPay QR code",
                  onTap: _scanAndPay,
                  iconColor: AppTheme.payAnywhereColor,
                ),
                ActionItemCard(
                  icon: Icons.qr_code,
                  title: "Get Paid with My QR",
                  subtitle: "Show your QR code so others can pay you",
                  onTap: _showMyQr,
                  iconColor: AppTheme.payAnywhereColor,
                ),
                ActionItemCard(
                  icon: Icons.receipt,
                  title: "Transaction History",
                  subtitle: "View all your payment history",
                  onTap: _openHistory,
                  iconColor: AppTheme.payAnywhereColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        QuickActionButton(
          icon: Icons.qr_code_scanner,
          label: "Scan QR",
          onTap: _scanAndPay,
          color: AppTheme.payAnywhereColor,
        ),
        QuickActionButton(
          icon: Icons.qr_code,
          label: "My QR",
          onTap: _showMyQr,
          color: AppTheme.payAnywhereColor,
        ),
        QuickActionButton(
          icon: Icons.send,
          label: "Send",
          onTap: () => Navigator.pushNamed(context, '/pay'),
          color: AppTheme.payAnywhereColor,
        ),
        QuickActionButton(
          icon: Icons.history,
          label: "History",
          onTap: _openHistory,
          color: AppTheme.payAnywhereColor,
        ),
      ],
    );
  }
}
