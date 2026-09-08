import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/main.dart';

import 'package:zentrapay_application/features/home/repository/cache_homeData.dart';
import 'provider_picker_sheet.dart';

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
  Future<List<Map<String, dynamic>>> _loadBillProviders() async {
    final providers = await BillProvidersRepository.instance.ensureLoaded();
    return (providers ?? [])
        .map(
          (p) => {
            'providerId': p.providerId,
            'billerName': p.billerName,
            'logoUrl': p.logoUrl ?? '',
            'category': p.categoryCode,
          },
        )
        .toList();
  }

  Future<List<Map<String, dynamic>>> _loadServiceProviders() async {
    final providers = await ServiceProvidersRepository.instance
        .ensureLoaded();
    return (providers ?? [])
        .map(
          (p) => {
            'providerId': p.providerId,
            'providerName': p.providerName,
            'logoUrl': p.logoUrl ?? '',
            'category': p.categoryCode,
          },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Both catalogs are empty — the whole section is hidden by the parent
    // (HomeWalletMain), but guard here too in case this widget is reused.
    if (widget.bills.isEmpty && widget.services.isEmpty) {
      return const SizedBox.shrink();
    }

    final isTablet = MediaQuery.of(context).size.width >= 600;
    final iconSize = isTablet ? 32.0 : 24.0;
    final fontSize = isTablet ? 14.0 : 12.0;

    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.bills.isNotEmpty) ...[
              Text("Bills", style: AppTheme.headlineMedium),
              const SizedBox(height: AppTheme.spacingSm),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.bills.length,
                        itemBuilder: (BuildContext context, int i) {
                          final item = widget.bills[i];
                          return _buildItem(
                            item['logoUrl'] ?? "",
                            item['billerName'] ?? "N/A",
                            () => showComingSoon(
                              context,
                              item['billerName'] ?? "N/A",
                            ),
                            iconSize: iconSize,
                            fontSize: fontSize,
                            isTablet: isTablet,
                            placeholderIcon: Icons.receipt_long,
                          );
                        },
                      ),
                    ),
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
            if (widget.bills.isNotEmpty && widget.services.isNotEmpty)
              const SizedBox(height: AppTheme.spacingXl),
            if (widget.services.isNotEmpty) ...[
              Text("Financial Services", style: AppTheme.headlineMedium),
              const SizedBox(height: AppTheme.spacingSm),
              SizedBox(
                width: MediaQuery.of(context).size.width,
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.services.length,
                        itemBuilder: (BuildContext context, int i) {
                          final item = widget.services[i];
                          return _buildItem(
                            item['logoUrl'] ?? "",
                            item['providerName'] ?? "N/A",
                            () => showComingSoon(
                              context,
                              item['providerName'] ?? "N/A",
                            ),
                            iconSize: iconSize,
                            fontSize: fontSize,
                            isTablet: isTablet,
                            placeholderIcon: Icons.account_balance,
                          );
                        },
                      ),
                    ),
                    _buildNewTile(
                      onTap: () => ProviderPickerSheet.show(
                        context,
                        title: "Service Providers",
                        loader: _loadServiceProviders,
                        nameKey: "providerName",
                        id: "Service Provider",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewTile({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_outlined, size: 20, color: AppColors.textBlack),
            const SizedBox(height: 4),
            Text(
              "New",
              style: TextStyle(
                color: AppColors.textBlack,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
    double fontSize = 12,
    required bool isTablet,
    IconData placeholderIcon = Icons.storefront,
  }) {
    final itemWidth =
        (MediaQuery.of(context).size.width - (isTablet ? 40 : 20) * 2 - 30) / 4;

    return SizedBox(
      width: itemWidth,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            imgUrl != ""
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(200),
                    child: Image.network(
                      imgUrl,
                      width: iconSize,
                      height: iconSize,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(placeholderIcon, color: Colors.black54, size: iconSize),
                    ),
                  )
                : Icon(placeholderIcon, color: Colors.black54, size: iconSize),

            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
      ),
    );
  }
}
