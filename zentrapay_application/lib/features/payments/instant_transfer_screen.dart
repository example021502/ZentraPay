import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/AppConfirmSheet.dart';
import 'package:zentrapay_application/core/utils/Common/EnterAmount.dart';

import '../../main.dart';
import 'transfer_user_selection.dart';

/// Screen for executing instant money transfers with payout methods and recipient validation.
class InstantTransferScreen extends StatefulWidget {
  const InstantTransferScreen({super.key});

  @override
  State<InstantTransferScreen> createState() => _InstantTransferScreenState();
}

class _InstantTransferScreenState extends State<InstantTransferScreen> {
  // Controller to handle input for recipient details dynamically based on payout option
  final TextEditingController _recipientDetailController =
      TextEditingController();

  // Controller to handle transaction amount input
  final TextEditingController _amountController = TextEditingController();

  // Selected payout method configuration default
  String selectedPayoutOption = 'Zentrapay Wallet';

  // Available African mobile money, wallet, and bank options
  final List<String> payoutOptions = [
    'Zentrapay Wallet',
    'MTN Mobile Money',
    'Vodafone Cash',
    'AirtelTigo Money',
    'M-Pesa',
    'Bank Account',
  ];

  @override
  void dispose() {
    _recipientDetailController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.main,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Instant Transfer",
          style: TextStyle(color: AppColors.primary, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        color: AppTheme.gray50,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15.0),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Fast transfers, right here.",
                          style: AppTheme.whiteHeadline,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Live rate",
                              style: AppTheme.labelSmall.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "1 USD = 1000 GHS",
                                  style: AppTheme.labelLarge.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  "Updated Just Now",
                                  style: AppTheme.labelSmall.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _buildTransferFeatureHighlight(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: AppTheme.cardDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Destination Payout Option",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildPayoutDropdown(),
                        const SizedBox(height: 20),
                        const Text(
                          "Recipient Details & Selection",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textBlack,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Transfer user selection component adjusted for payout method context
                        TransferUserSelection(
                          payoutOption: selectedPayoutOption,
                          onRecipientSelected: _handleRecipientSelection,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the dropdown selector for destination payout methods.
  Widget _buildPayoutDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPayoutOption,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: AppColors.textBlack),
          items: payoutOptions.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textBlack,
                ),
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedPayoutOption = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  /// Builds a small modern informational badge highlighting instant speed benefits.
  Widget _buildTransferFeatureHighlight() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.green.withAlpha(20),
              borderRadius: BorderRadius.circular(200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: const Icon(Icons.bolt, color: AppColors.green, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Lightning Fast Delivery",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Funds arrive in recipient destination instantly, 24/7.",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Callback when a recipient is chosen from selection component.
  Future<void> _handleRecipientSelection(SelectedRecipient recipient) async {
    final amount = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnterAmount(recipient: recipient.displayName),
    );
    if (amount == null || !mounted) return;
    final Map<String, dynamic> form = {};

    final bool? isConfirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildReviewSummarySheet(context, form),
    );

    if (isConfirmed != true || !mounted) return;

    final pin = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AppConfirmPinSheet(name: '', currencyCode: '', amount: ''),
    );
  }

  /// Builds a modern confirmation summary sheet for user cross-reference.
  Widget _buildReviewSummarySheet(
    BuildContext context,
    Map<String, dynamic> form,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Review Transfer",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),
          _buildSummaryRow("Payout Option", form['payoutOption']),
          _buildSummaryRow("Recipient Name", form['name']),
          if (form['zentag'] != null)
            _buildSummaryRow("Zentag", form['zentag']),
          if (form['phoneNumber'] != null)
            _buildSummaryRow("Phone / Account", form['phoneNumber']),
          _buildSummaryRow(
            "Amount",
            "${form['currency_code']} ${form['amount']}",
          ),
          _buildSummaryRow("Transfer Speed", "Instant (24/7)"),
          _buildSummaryRow("Estimated Fee", "Free"),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                "Confirm & Continue to PIN",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textBlack,
            ),
          ),
        ],
      ),
    );
  }
}
