import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

import 'transfer_user_selection.dart';
import 'package:zentrapay_application/features/zremit/zremit_header.dart';

class InstantTransferScreen extends StatelessWidget {
  const InstantTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.main,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ZRemitHeader(title: "Instant Money Transfer", showBack: true),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: const Column(
                children: [
                  TransferUserSelection(),
                  Divider(thickness: 8, color: Color(0xFFF5F5F5)),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
