import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Common/provider_display.dart';

class HomeServicesGrid extends StatefulWidget {
  const HomeServicesGrid({
    super.key,
    required this.services,
    required this.bills,
  });

  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> bills;

  @override
  State<HomeServicesGrid> createState() => _HomeServicesGridState();
}

class _HomeServicesGridState extends State<HomeServicesGrid> {
  @override
  Widget build(BuildContext context) {
    // Both catalogs are empty — the whole section is hidden by the parent
    // (HomeWalletMain), but guard here too in case this widget is reused.
    if (widget.bills.isEmpty && widget.services.isEmpty) {
      return const SizedBox.shrink();
    }

    final isTablet = MediaQuery.of(context).size.width >= 600;
    final iconSize = isTablet ? 32.0 : 24.0;

    // Section layout mirrors HomeTransactions ("Latest Activities"): top
    // spacing, a small bodyMedium heading, then spacingMd before the rows —
    // no outer padding here, the parent column already pads the screen.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.bills.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingXl),
          Text("Bills", style: AppTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            height: 80,
            child: Row(
              children: [
                // Providers scroll on the LEFT; Expanded pins the row's
                // width so the New tile can never be squeezed out. (A bare
                // ListView here would greedily eat the whole width and
                // collapse the tile — one scroll container only.)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final item in widget.bills)
                          _buildItem(
                            item['logoUrl'] ?? "",
                            item['billerName'] ?? "N/A",
                            () => showComingSoon(
                              context,
                              item['billerName'] ?? "N/A",
                            ),
                            iconSize: iconSize,
                            categoryCode: item['category']?.toString(),
                            countryCode: item['countryCode']?.toString(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                // Pinned to the RIGHT edge of the section, outside the
                // scroll area — always visible no matter how far the list
                // has scrolled.
                _buildNewTile(
                  onTap: () {
                    showComingSoon(context, "Linked new bill provider");
                  },
                ),
              ],
            ),
          ),
        ],
        if (widget.services.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingXl),
          Text("Services", style: AppTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            height: 80,
            child: Row(
              children: [
                // Same shape as Bills: scrollable providers left, New right.
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final item in widget.services)
                          _buildItem(
                            item['logoUrl'] ?? "",
                            item['providerName'] ?? "N/A",
                            () => showComingSoon(
                              context,
                              item['providerName'] ?? "N/A",
                            ),
                            iconSize: iconSize,
                            categoryCode: item['category']?.toString(),
                            countryCode: item['countryCode']?.toString(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _buildNewTile(
                  onTap: () {
                    showComingSoon(context, "Linked new service provider");
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNewTile({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: AppTheme.spacingMd),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Same tinted icon-chip treatment as TransactionListItem's leading
            // chip, so the "+" tile reads as part of the same design system.
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppTheme.primaryPink.withAlpha(25),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(
                Icons.add_outlined,
                size: 22,
                color: AppTheme.textBlack,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              "New",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    String imgUrl,
    String label,
    VoidCallback onTap, {
    double iconSize = 24,
    String? categoryCode,
    String? countryCode,
  }) {
    // Fixed tile width so the horizontal rows keep a consistent rhythm
    // (icon chip + label) regardless of screen size.
    const double itemWidth = 76;

    // Visual priority: logo -> country flag -> category icon. A provider
    // without a logo still gets a meaningful, corridor-specific glyph (the
    // flag from its country code), with the category icon as the last
    // resort (see ProviderDisplay.dart / Datatypes.ProviderCategory).
    final String flag = countryCodeToFlag(countryCode);

    Widget visual;
    if (imgUrl != "") {
      visual = ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        child: Image.network(
          imgUrl,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallbackVisual(
            flag: flag,
            categoryCode: categoryCode,
            iconSize: iconSize,
          ),
        ),
      );
    } else {
      visual = _fallbackVisual(
        flag: flag,
        categoryCode: categoryCode,
        iconSize: iconSize,
      );
    }

    return SizedBox(
      width: itemWidth,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.only(right: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tinted icon chip — matches the TransactionListItem leading chip
              // (radiusMd container, secondaryNavy icon) used by the home
              // transactions section.
              visual,
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textBlack),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Flag when the country code is usable, category icon otherwise.
  Widget _fallbackVisual({
    required String flag,
    required String? categoryCode,
    required double iconSize,
  }) {
    if (flag.isNotEmpty) {
      return Text(flag, style: TextStyle(fontSize: iconSize), maxLines: 1);
    }
    return Icon(
      providerCategoryIcon(categoryCode),
      color: AppTheme.textBlack,
      size: iconSize,
    );
  }
}
