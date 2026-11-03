import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/features/payments/z_remit_form.dart';
import 'package:zentrapay_application/main.dart';

import 'zremit_header.dart';

/// Screen for sending money abroad (cross-border) to people, banks and mobile money.
class ZRemitScreen extends StatelessWidget {
  const ZRemitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SectionScrollView(
      header: SectionHeader(
        title: 'ZRemit',
        subtitle: 'Send money abroad to people, banks and mobile money',
        icon: Icons.public_rounded,
        sheetColor: AppTheme.gray50,
        actions: [
          _headerActionPill(
            label: 'Convert',
            onTap: () => Navigator.pushNamed(context, '/converter'),
          ),
        ],
        child: const ZRemitHeader(),
      ),
      sheet: SectionSheet(
        color: AppTheme.gray50,
        topPadding: AppTheme.spacingMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [ZRemitForm(), SizedBox(height: 100)],
        ),
      ),
    );
  }

  // Same labelled pill as the ZBank header's call to action.
  Widget _headerActionPill({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.primary.withAlpha(36),
      shape: StadiumBorder(
        side: BorderSide(color: AppColors.primary.withAlpha(90)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.currency_exchange,
                size: 16,
                color: AppTheme.primaryWhite,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTheme.labelLarge.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
