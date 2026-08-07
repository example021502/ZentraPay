import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/payments/ZRemitForm.dart';
import 'package:zentrapay_application/main.dart';

import 'zremit_header.dart';

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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.gray50,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
        child: Column(
          spacing: 20,
          children: [
            const ZRemitHeader(),
            _buildHeroCard(),
            // SearchBarWidget(
            //   controller: _searchController,
            //   focusNode: _searchFocusNode,
            //   hintText: "Search Recipient...",
            // ),
            ZRemitForm(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      mainAxisSize: MainAxisSize.max,
      children: [
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(200),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15.0, 8, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.currency_exchange,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    "Currency\nConversion",
                    style: AppTheme.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(200),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 5, 15, 5),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.bolt,
                          size: 22,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    "Instant transfer",
                    style: AppTheme.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

}
