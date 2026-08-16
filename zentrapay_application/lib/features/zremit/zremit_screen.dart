import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/payments/ZRemitForm.dart';
import 'package:zentrapay_application/main.dart';

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
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        children: [
          const ZRemitHeader(),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.gray50,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 20),
                  // Wrapped form widget ensuring it doesn't contain unconstrained inner widgets
                  const ZRemitForm(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Builds the hero feature cards horizontally
  Widget _buildHeroCard() {
    return GestureDetector(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        mainAxisSize: MainAxisSize.max,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/converter");
            },
            child: Container(
              decoration: AppTheme.cardDecoration,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15.0, 10, 20, 10),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.currency_exchange,
                          size: 22,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      "Currency\nConversion",
                      style: AppTheme.labelSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingLg),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/instant_transfer");
            },
            child: Container(
              decoration: AppTheme.cardDecoration,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10.0, 10, 15, 10),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Icon(
                          Icons.bolt,
                          size: 22,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Text(
                      "Instant transfer",
                      style: AppTheme.labelSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
