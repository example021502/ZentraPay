import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Common/provider_display.dart';
import 'package:zentrapay_application/core/models/user_service.dart';
import 'package:zentrapay_application/features/home/bill_payment_sheet.dart';
import 'package:zentrapay_application/features/home/repository/cache_user_services_data.dart';
import 'package:zentrapay_application/main.dart';

/// Searchable bottom sheet listing providers fetched from [loader].
/// Used both by Quick Actions' "More" popup (New Bill Provider / New
/// Service Provider) and the "+ New" tiles on the Home services grid.
///
/// [nameKey] picks which field holds the provider's display name
/// ("billerName" for bill providers, "providerName" for service providers).
class ProviderPickerSheet extends StatefulWidget {
  const ProviderPickerSheet({
    super.key,
    required this.title,
    required this.loader,
    required this.nameKey,
    required this.id,
  });

  final String title;
  final String id;
  final Future<List<Map<String, dynamic>>> Function() loader;
  final String nameKey;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required Future<List<Map<String, dynamic>>> Function() loader,
    required String nameKey,
    required String id,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ProviderPickerSheet(
          title: title,
          loader: loader,
          nameKey: nameKey,
          id: id,
        ),
      ),
    );
  }

  @override
  State<ProviderPickerSheet> createState() => _ProviderPickerSheetState();
}

class _ProviderPickerSheetState extends State<ProviderPickerSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // After the first frame: loading notifies repository listeners (the Home grid), which
    // must not happen while this sheet is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Which ones are already on Home (the toggle's state); a failure here only
      // means the toggles start unchecked.
      final mine = UserServicesRepository.instance.ensureLoaded().then<void>(
        (_) {},
        onError: (_) {},
      );
      final providers = await widget.loader();
      await mine;
      if (!mounted) return;
      setState(() {
        _providers = providers;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not load providers. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _providers;
    return _providers.where((p) {
      final name = (p[widget.nameKey] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  // Bill providers open the real payment form (/api/bill-providers/pay). Service
  // providers are a directory only - the backend has no payment contract for them
  // yet - so they open a detail card that says so instead of a dead "coming soon".
  void _showProviderDetails(Map<String, dynamic> provider) {
    final name = (provider[widget.nameKey] ?? 'Provider').toString();
    if (widget.id == "Bill Providers") {
      // Shown on top of this still-open picker sheet; closes both once paid
      BillPaymentSheet.show(
        context,
        providerId: (provider['providerId'] ?? '').toString(),
        providerName: name,
      ).then((paid) {
        if (paid && mounted) Navigator.pop(context);
      });
      return;
    }
    showServiceProviderCard(context, provider, name);
  }

  String get _kind =>
      widget.id == "Bill Providers" ? UserService.bill : UserService.service;

  final Set<String> _busy = {};

  Widget _buildHomeToggle(Map<String, dynamic> provider, String name) {
    final providerId = (provider['providerId'] ?? '').toString();
    final added = UserServicesRepository.instance.has(_kind, providerId);
    if (_busy.contains(providerId)) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.main),
      );
    }
    return IconButton(
      key: ValueKey('home-toggle-$providerId'),
      tooltip: added ? 'Remove from Home' : 'Add to Home',
      icon: Icon(
        added ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
        color: added ? AppColors.main : AppTheme.textBlack,
      ),
      onPressed: () => _toggle(providerId, name, added),
    );
  }

  Future<void> _toggle(String providerId, String name, bool added) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy.add(providerId));
    try {
      if (added) {
        await UserServicesRepository.instance.remove(_kind, providerId);
      } else {
        await UserServicesRepository.instance.add(_kind, providerId);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            added ? '$name removed from Home' : '$name added to Home',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not ${added ? 'remove' : 'add'} $name. Try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy.remove(providerId));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4.5,
            decoration: BoxDecoration(
              color: AppTheme.gray300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              AppTheme.spacingLg,
              AppTheme.spacingLg,
              AppTheme.spacingMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppTheme.headlineLarge),
                const SizedBox(height: AppTheme.spacingMd),
                SearchBarWidget(
                  controller: _searchController,
                  hintText: 'Search...',
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.main),
      );
    }
    if (_error != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        message: _error!,
        actionLabel: 'Retry',
        onAction: _load,
      );
    }
    final providers = _filtered;
    if (providers.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.storefront_outlined,
        message: 'No ${widget.id} found',
        actionLabel: "Add New",
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      itemCount: providers.length,
      itemBuilder: (context, i) {
        final provider = providers[i];
        final name = (provider[widget.nameKey] ?? 'N/A').toString();
        final logoUrl = (provider['logoUrl'] ?? '').toString();
        final category = (provider['category'] ?? '').toString();
        // Same visual priority as the home services grid: logo -> country
        // flag -> category icon (ProviderDisplay.dart).
        final flag = countryCodeToFlag(provider['countryCode']?.toString());
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.cardShadow,
          ),
          // Transparent Material so the tile's ink isn't hidden by the decorated card.
          child: Material(
            type: MaterialType.transparency,
            child: ListTile(
              leading: logoUrl.isNotEmpty
                  ? CircleAvatar(backgroundImage: NetworkImage(logoUrl))
                  : CircleAvatar(
                      backgroundColor: AppColors.main.withAlpha(25),
                      child: flag.isNotEmpty
                          ? Text(flag, style: const TextStyle(fontSize: 20))
                          : Icon(
                              providerCategoryIcon(category),
                              color: AppTheme.textBlack,
                            ),
                    ),
              title: Text(name, style: AppTheme.titleLarge),
              subtitle: category.isNotEmpty ? Text(category) : null,
              // Add to / remove from the user's Home screen (user_services).
              trailing: _buildHomeToggle(provider, name),
              onTap: () => _showProviderDetails(provider),
            ),
          ),
        );
      },
    );
  }
}

/// Detail card for a service provider (a directory entry; no payment contract yet).
void showServiceProviderCard(
  BuildContext context,
  Map<String, dynamic> provider,
  String name,
) {
  final category = (provider['category'] ?? '').toString();
  showModalBottomSheet(
    context: context,
    backgroundColor: AppTheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTheme.headlineSmall),
            if (category.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                category,
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
              ),
            ],
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              "Paying a service provider straight from ZentraPay isn't switched on yet. "
              "You can still pay people and businesses from Send, and utilities from Bill Providers.",
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'Close',
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
