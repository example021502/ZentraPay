import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/models/bill_service_provider.dart';
import 'package:zentrapay_application/features/home/bill_payment_sheet.dart';
import 'package:zentrapay_application/features/home/provider_picker_sheet.dart';
import 'package:zentrapay_application/core/models/user_service.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/home/repository/cache_user_services_data.dart';
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
    // Nothing added yet: the whole section is removed from Home. The first bill provider /
    // service is added from the "More" overlay of the quick actions.
    if (widget.bills.isEmpty && widget.services.isEmpty) {
      return const SizedBox.shrink();
    }

    // Once the user has added something, both rows show (even if one is empty) so each
    // keeps its pinned "New" tile. Only what they added is listed.
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final iconSize = isTablet ? 32.0 : 24.0;

    // Section layout mirrors HomeTransactions ("Latest Activities"): top
    // spacing, a small bodyMedium heading, then spacingMd before the rows —
    // no outer padding here, the parent column already pads the screen.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...[
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
                            () => BillPaymentSheet.show(
                              context,
                              providerId: (item['providerId'] ?? '').toString(),
                              providerName: (item['billerName'] ?? 'Provider')
                                  .toString(),
                            ),
                            iconSize: iconSize,
                            categoryCode: item['category']?.toString(),
                            countryCode: item['countryCode']?.toString(),
                            onLongPress: () => _confirmRemove(
                              UserService.bill,
                              (item['providerId'] ?? '').toString(),
                              (item['billerName'] ?? 'this provider')
                                  .toString(),
                            ),
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
                  onTap: () => ProviderPickerSheet.show(
                    context,
                    title: "Bill Providers",
                    loader: _loadBillProviders,
                    nameKey: "billerName",
                    id: "Bill Providers",
                  ),
                ),
              ],
            ),
          ),
        ],
        ...[
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
                            () => showServiceProviderCard(
                              context,
                              item,
                              (item['providerName'] ?? 'Provider').toString(),
                            ),
                            iconSize: iconSize,
                            categoryCode: item['category']?.toString(),
                            countryCode: item['countryCode']?.toString(),
                            onLongPress: () => _confirmRemove(
                              UserService.service,
                              (item['providerId'] ?? '').toString(),
                              (item['providerName'] ?? 'this service')
                                  .toString(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _buildNewTile(
                  onTap: () => ProviderPickerSheet.show(
                    context,
                    title: "Service Providers",
                    loader: _loadServiceProviders,
                    nameKey: "providerName",
                    id: "Service Providers",
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Long-press on a Home tile: take it off the user's Home screen (not out of the directory).
  Future<void> _confirmRemove(
    String kind,
    String providerId,
    String name,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from Home?'),
        content: Text(
          '$name will no longer show here. You can add it again with New.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await UserServicesRepository.instance.remove(kind, providerId);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not remove it. Try again.')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadBillProviders() async {
    final providers =
        await BillProvidersRepository.instance.ensureLoaded() ??
        <BillProvider>[];
    return providers
        .map(
          (p) => {
            'providerId': p.providerId,
            'billerName': p.billerName,
            'logoUrl': p.logoUrl ?? '',
            'category': p.categoryCode,
            'countryCode': p.countryCode ?? '',
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _loadServiceProviders() async {
    final providers =
        await ServiceProvidersRepository.instance.ensureLoaded() ??
        <ServiceProvider>[];
    return providers
        .map(
          (p) => {
            'providerId': p.providerId,
            'providerName': p.providerName,
            'logoUrl': p.logoUrl ?? '',
            'category': p.categoryCode,
            'countryCode': p.countryCode ?? '',
          },
        )
        .toList();
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
    VoidCallback? onLongPress,
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
        onLongPress: onLongPress,
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
