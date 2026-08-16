import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/repositories/wallets_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';

/// The Home "Receive" quick action: one card per fiat currency account the
/// user owns, each carrying its own zentag (accounts, not users, are the
/// payable identity now — see WalletsRepository). The default account's QR
/// is shown open; every other account is collapsed behind a show/hide
/// button but still shows its name/currency/zentag. The QR itself is built
/// and rendered entirely on-device from the account's own zentag — nothing
/// image-shaped is fetched from the backend.
///
/// Sourced from [WalletsRepository]'s existing cache — the sheet doesn't
/// hit the network on its own, it just reads whatever Home already loaded
/// (and triggers a load if nothing has fetched yet).
class ReceiveSheet extends StatefulWidget {
  const ReceiveSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.primaryWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const ReceiveSheet(),
    );
  }

  @override
  State<ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends State<ReceiveSheet> {
  /// accountId -> whether a non-default account's QR is currently shown.
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    WalletsRepository.instance.ensureLoaded();
  }

  /// The payload a sender's scanner reads — enough to resolve exactly which
  /// currency account to pay into without a name-search round trip.
  String _qrPayload(FiatAccount account) =>
      'zentrapay://pay?zentag=${Uri.encodeComponent(account.zentag)}'
      '&currency=${Uri.encodeComponent(account.currencyCode)}'
      '&accountId=${Uri.encodeComponent(account.accountId)}';

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ZentraNotifier.success("Copied", "$label copied to clipboard.");
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Padding(
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
            const Padding(
              padding: EdgeInsets.all(AppTheme.spacingLg),
              child: Text("Receive Money", style: AppTheme.headlineLarge),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ListenableBuilder(
      listenable: WalletsRepository.instance,
      builder: (context, _) {
        final repo = WalletsRepository.instance;

        if (repo.isLoading && !repo.isLoaded) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.main),
          );
        }
        if (repo.error != null && !repo.isLoaded) {
          return EmptyStateWidget(
            icon: Icons.error_outline,
            message: "Could not load your accounts.",
            actionLabel: "Retry",
            onAction: () => repo.ensureLoaded(forceRefresh: true),
          );
        }

        final accounts = [...repo.data?.fiatAccounts ?? []];
        if (accounts.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.account_balance_wallet_outlined,
            message: "No currency accounts yet — create a wallet first.",
          );
        }

        // Default account leads the list; the rest keep their fetch order.
        accounts.sort((a, b) {
          if (a.isDefault == b.isDefault) return 0;
          return a.isDefault ? -1 : 1;
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final account in accounts) ...[
                _buildAccountCard(account),
                const SizedBox(height: AppTheme.spacingLg),
              ],
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccountCard(FiatAccount account) {
    final showQr = account.isDefault || _expanded.contains(account.accountId);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            account.accountName,
                            style: AppTheme.titleLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (account.isDefault) ...[
                          const SizedBox(width: AppTheme.spacingXs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.main.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                            child: const Text(
                              "Default",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.main,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      "${account.currencyCode} · @${account.zentag}",
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.gray500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!account.isDefault)
                TextButton.icon(
                  onPressed: () => setState(() {
                    if (showQr) {
                      _expanded.remove(account.accountId);
                    } else {
                      _expanded.add(account.accountId);
                    }
                  }),
                  icon: Icon(
                    showQr ? Icons.visibility_off : Icons.qr_code_2,
                    size: 18,
                  ),
                  label: Text(showQr ? "Hide QR" : "Show QR"),
                ),
            ],
          ),
          if (showQr) ...[
            const SizedBox(height: AppTheme.spacingLg),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.gray50,
                border: Border.all(color: AppTheme.gray300, width: 1.5),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: QrImageView(
                data: _qrPayload(account),
                version: QrVersions.auto,
                size: 180,
                backgroundColor: AppTheme.gray50,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppTheme.textBlack,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppTheme.textBlack,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextButton.icon(
              onPressed: () => _copy(account.zentag, "Zentag"),
              icon: const Icon(Icons.alternate_email, size: 18),
              label: const Text("Copy Zentag"),
            ),
          ],
        ],
      ),
    );
  }
}
