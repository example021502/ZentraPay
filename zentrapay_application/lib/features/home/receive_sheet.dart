import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/main.dart';

/// The Home "Receive" quick action: shows the current user's zentag, a QR
/// payload (rendered as a placeholder glyph — no `qr_flutter` dependency in
/// this project yet, so the payload is copyable/shareable as text instead of
/// a scannable image), and their linked bank accounts, all sourced from
/// `GET /api/users/me/receive` in one call.
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
  static final Dio _dio = ApiClient().dio;

  Map<String, dynamic>? _info;
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
      final response = await _dio.get('/api/users/me/receive');
      if (!mounted) return;
      setState(() => _info = response.data['data']);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = "Could not load your receive details.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.main),
      );
    }
    if (_error != null || _info == null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        message: _error ?? "Something went wrong.",
        actionLabel: "Retry",
        onAction: _load,
      );
    }

    final zentag = _info!['zentag'] ?? '';
    final fullName = _info!['fullName'] ?? '';
    final qrPayload = _info!['qrPayload'] ?? '';
    final linkedAccounts =
        (_info!['linkedAccounts'] as List?)?.cast<Map<String, dynamic>>() ??
        const [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            decoration: AppTheme.cardDecoration,
            child: Column(
              children: [
                Text(fullName, style: AppTheme.titleLarge),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  "@$zentag",
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.gray500,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.gray50,
                    border: Border.all(color: AppTheme.gray300, width: 1.5),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: const Icon(
                    Icons.qr_code_2,
                    size: 150,
                    color: AppTheme.textBlack,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextButton.icon(
                  onPressed: () => _copy(qrPayload, "Receive link"),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text("Copy Receive Link"),
                ),
                TextButton.icon(
                  onPressed: () => _copy(zentag, "Zentag"),
                  icon: const Icon(Icons.alternate_email, size: 18),
                  label: const Text("Copy Zentag"),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text("Linked Bank Accounts", style: AppTheme.headlineSmall),
          const SizedBox(height: AppTheme.spacingMd),
          if (linkedAccounts.isEmpty)
            const AppCard(
              child: EmptyStateWidget(
                icon: Icons.account_balance_outlined,
                message: "No bank accounts linked yet.",
              ),
            )
          else
            ...linkedAccounts.map(
              (a) => Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.secondary.withAlpha(20),
                      child: const Icon(
                        Icons.account_balance,
                        color: AppColors.secondary,
                      ),
                    ),
                    title: Text(a['sourceName'] ?? ''),
                    subtitle: Text(a['accountIdentifier'] ?? ''),
                    trailing: (a['verified'] == true)
                        ? const Icon(
                            Icons.verified,
                            color: AppTheme.successGreen,
                            size: 20,
                          )
                        : null,
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  void _copy(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ZentraNotifier.success("Copied", "$label copied to clipboard.");
  }
}
