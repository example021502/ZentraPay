import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/repositories/transactions_repository.dart';
import 'package:zentrapay_application/core/repositories/wallets_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Common/AppConfirmSheet.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final providers = await widget.loader();
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

  // Bill providers have a real pay-a-biller endpoint (/api/bill-providers/pay)
  // to submit against, so selecting one opens the actual payment form.
  // Service providers don't have an equivalent backend endpoint yet, so
  // that path still falls back to "coming soon" rather than pretending.
  void _showProviderDetails(Map<String, dynamic> provider) {
    final name = provider[widget.nameKey] ?? 'Provider';
    if (widget.id == "Bill Providers") {
      // Shown on top of this still-open picker sheet (stacked modal routes
      // are fine) rather than popping first — that would leave us without
      // a reliably-mounted context to open the next sheet from.
      _showBillPaymentForm(provider);
      return;
    }
    Navigator.pop(context);
    showComingSoon(context, name.toString());
  }

  void _showBillPaymentForm(Map<String, dynamic> provider) {
    final providerId = (provider['providerId'] ?? '').toString();
    final name = (provider[widget.nameKey] ?? 'Provider').toString();
    if (providerId.isEmpty) {
      ZentraNotifier.error(
        "Missing Provider",
        "This provider can't be paid right now — try again later.",
      );
      return;
    }

    final referenceController = TextEditingController();
    final amountController = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            left: AppTheme.spacingLg,
            right: AppTheme.spacingLg,
            top: AppTheme.spacingLg,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Pay $name", style: AppTheme.headlineSmall),
                  const SizedBox(height: AppTheme.spacingMd),
                  AppTextField(
                    controller: referenceController,
                    labelText: 'Customer reference',
                    hintText: 'e.g. meter or account number',
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  AppTextField(
                    controller: amountController,
                    labelText: 'Amount (GHS)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submitting
                          ? null
                          : () async {
                              final reference = referenceController.text.trim();
                              final amount = amountController.text.trim();
                              final parsedAmount = double.tryParse(amount);
                              if (reference.isEmpty) {
                                ZentraNotifier.error(
                                  'Missing Reference',
                                  'Enter your customer reference for $name.',
                                );
                                return;
                              }
                              if (parsedAmount == null || parsedAmount <= 0) {
                                ZentraNotifier.error(
                                  'Invalid Amount',
                                  'Enter a valid amount greater than zero.',
                                );
                                return;
                              }

                              final pin = await showModalBottomSheet<String>(
                                context: sheetContext,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => AppConfirmPinSheet(
                                  name: 'Placeholder',
                                  currencyCode: 'Placeholder',
                                  amount: 'Placeholder',
                                ),
                              );
                              if (pin == null || pin.isEmpty) return;

                              setSheetState(() => submitting = true);
                              try {
                                await _payBillProvider(
                                  pin: pin,
                                  providerId: providerId,
                                  customerReference: reference,
                                  amount: amount,
                                  currencyCode: 'GHS',
                                );
                                if (sheetContext.mounted) {
                                  // Close the payment form...
                                  Navigator.pop(sheetContext);
                                }
                                if (mounted) {
                                  // ...and the provider picker underneath it.
                                  Navigator.pop(context);
                                }
                                ZentraNotifier.success(
                                  'Payment Successful',
                                  'Paid GHS $amount to $name.',
                                );
                              } catch (e) {
                                setSheetState(() => submitting = false);
                                ZentraNotifier.error(
                                  'Payment Failed',
                                  'Could not complete this bill payment. Try again.',
                                );
                              }
                            },
                      child: submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Pay Now'),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _payBillProvider({
    required String pin,
    required String providerId,
    required String customerReference,
    required String amount,
    required String currencyCode,
  }) async {
    final dio = ApiClient().dio;
    final response = await dio.post(
      '/api/bill-providers/pay',
      data: {
        'pin': pin,
        'providerId': providerId,
        'customerReference': customerReference,
        'amount': amount,
        'currencyCode': currencyCode,
      },
    );
    final data = response.data['data'];
    final transactionJson = data?['transaction'];
    if (transactionJson != null) {
      TransactionsRepository.instance.prepend(
        AppTransaction.fromJson(transactionJson),
      );
    }
    WalletsRepository.instance.ensureLoaded();
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
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppTheme.primaryWhite,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.cardShadow,
          ),
          child: ListTile(
            leading: logoUrl.isNotEmpty
                ? CircleAvatar(backgroundImage: NetworkImage(logoUrl))
                : CircleAvatar(
                    backgroundColor: AppColors.main.withAlpha(25),
                    child: Icon(Icons.storefront, color: AppColors.main),
                  ),
            title: Text(name, style: AppTheme.titleLarge),
            subtitle: category.isNotEmpty ? Text(category) : null,
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _showProviderDetails(provider),
          ),
        );
      },
    );
  }
}
