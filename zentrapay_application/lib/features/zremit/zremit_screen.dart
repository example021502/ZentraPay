import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/payments/z_remit_form.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';

import 'zremit_header.dart';

/// Screen for handling international remittances and currency transfers.
class ZRemitScreen extends StatefulWidget {
  const ZRemitScreen({super.key});

  @override
  State<ZRemitScreen> createState() => _ZRemitScreenState();
}

class _ZRemitScreenState extends State<ZRemitScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    // Dispose controllers and focus nodes to prevent memory leaks
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionScrollView(
      header: SectionHeader(
        title: "ZRemit",
        subtitle: "Send money abroad to people, banks and mobile money",
        icon: Icons.public_rounded,
        sheetColor: AppTheme.gray50,
        child: const ZRemitHeader(),
      ),
      sheet: SectionSheet(
        color: AppTheme.gray50,
        topPadding: 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(),
            const SizedBox(height: AppTheme.spacingXl),
            const ZRemitForm(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // The currency conversion shortcut, styled like the Home quick actions.
  Widget _buildHeroCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        QuickActionButton(
          icon: Icons.currency_exchange,
          label: "Convert",
          onTap: () => Navigator.pushNamed(context, "/converter"),
        ),
      ],
    );
  }
}
