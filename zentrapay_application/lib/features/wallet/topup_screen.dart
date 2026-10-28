import 'dart:async';

import 'package:flutter/material.dart';
import 'package:paystack_flutter_sdk/paystack_flutter_sdk.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/wallet/topup_service.dart';
import 'package:zentrapay_application/main.dart';

class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _amountController = TextEditingController();
  final _phoneController = TextEditingController();

  // Funding source: 'bank' | 'mobile_money'
  String _source = 'bank';
  // Payment method: 'card' | 'bank_transfer' | 'mobile_money'
  String _method = 'card';
  // Mobile money network
  String _momoNetwork = 'MTN';

  bool _initiating = false;
  bool _verifying = false;
  TopupInitResponse? _init;
  String? _error;

  final _paystack = Paystack();

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _title => 'Top Up Wallet';
  String get _subtitle => 'Add money from your bank or mobile money';

  // ------------------------------------------------------------------
  // UI build
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return SectionScrollView(
      header: SectionHeader(
        title: _title,
        subtitle: _subtitle,
        icon: Icons.add_circle_outline,
        sheetColor: AppTheme.gray50,
        actions: [Icon(Icons.handshake)],
      ),
      sheet: SectionSheet(
        color: AppTheme.gray50,
        topPadding: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Funding source
            Text('Funding source'),
            // _sourceRow(),
            const SizedBox(height: AppTheme.spacingLg),

            // Amount
            Text('Amount (GHS)'),
            AppTextField(
              controller: _amountController,
              labelText: 'Enter amount',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const SizedBox(height: AppTheme.spacingLg),

            // Initiate / Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brand,
                  foregroundColor: AppTheme.primaryWhite,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {},
                child: _initiating || _verifying
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        _init == null ? 'Continue' : 'Verify Payment',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }
}
