import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/AppPinSheet.dart';
import 'package:zentrapay_application/core/utils/Common/EnterAmount.dart';

import 'transfer_user_selection.dart';
import 'package:zentrapay_application/features/zremit/zremit_header.dart';

class InstantTransferScreen extends StatefulWidget {
  const InstantTransferScreen({super.key});

  @override
  State<InstantTransferScreen> createState() => _InstantTransferScreenState();
}

class _InstantTransferScreenState extends State<InstantTransferScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryPink,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ZRemitHeader(title: "Instant Money Transfer", showBack: true),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.primaryWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  TransferUserSelection(onRecipientSelected: _startTransfer),
                  const Divider(thickness: 8, color: Color(0xFFF5F5F5)),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startTransfer(SelectedRecipient recipient) async {
    final amount = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnterAmount(recipient: recipient.displayName),
    );
    if (amount == null || !mounted) return;

    final form = {
      'recipientType': 'app-user',
      'name': recipient.displayName,
      'phoneNumber': recipient.phoneNumber,
      'zentag': recipient.zentag,
      'amount': amount['amount'],
      'currency_code': amount['currency_code'],
    };

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AppPinSheet.confirmTransaction(form: form),
    );
  }
}
