import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/features/home/generate_qr_code.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';

/// The `zentrapay://pay` payload encoded in an account's receive QR. Shared by
/// the Receive sheet and the Profile screen so both show the same code. Empty
/// while the receiver's details ([info]) are still loading.
String buildAccountQrPayload(FiatAccount account, UserQRInfo? info) {
  if (info == null) return '';
  final userName = "${info.firstName} ${info.lastName}".trim();
  return 'zentrapay://pay?'
      'zentag=${Uri.encodeComponent(account.zentag)}'
      '&currency=${Uri.encodeComponent(account.currencyCode)}'
      '&accountId=${Uri.encodeComponent(account.accountId)}'
      '&userId=${Uri.encodeComponent(info.userId)}'
      '&name=${Uri.encodeComponent(userName)}'
      '&email=${Uri.encodeComponent(info.email)}'
      '&phoneNumber=${Uri.encodeComponent(info.phoneNumber)}'
      '&countryCode=${Uri.encodeComponent(info.countryCode)}'
      '&userType=${Uri.encodeComponent(info.userType)}';
}

/// The Home "Receive" quick action: renders pretty QR codes for fiat currency accounts.
/// Integrates user details (Name, Email, Phone) from [UserQRRepository] and wallet info
/// from [WalletsRepository].
class ReceiveSheet extends StatefulWidget {
  const ReceiveSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => const ReceiveSheet(),
    );
  }

  @override
  State<ReceiveSheet> createState() => _ReceiveSheetState();
}

class _ReceiveSheetState extends State<ReceiveSheet> {
  /// Tracks expanded account QRs (non-default wallets)
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    // Comment: Trigger data loading for both repositories on init.
    // Fire-and-forget futures surface unhandled-async crashes when offline,
    // so swallow errors here — _buildBody already renders error + retry UI.
    WalletsRepository.instance.ensureLoaded().catchError((_) => null);
    UserQRRepository.instance.loadQRUserInfo().catchError((_) => null);
  }

  /// Builds a comprehensive URI payload including account & user identity info.
  /// Every field here is something the scanner needs to hand the payments
  /// backend: `zentag`/`phoneNumber` route the money, `name`/`countryCode`/
  /// `userType` fill the backend's `AppUserDetails`, `userId` identifies the
  /// receiver for re-searches/records, and `currency`/`accountId` tell the
  /// sender which account (and therefore currency) the receiver expects.
  ///
  /// Null-safe: userData can be null while the profile is still loading (or
  /// when the request failed). The QR view guards empty data, so never force
  /// unwrap here — a crash in _qrPayload used to take down the whole sheet.
  String _qrPayload(FiatAccount account, UserQRRepository userRepo) =>
      buildAccountQrPayload(account, userRepo.userData);

  void _copy(String value, String label) {
    if (value.trim().isEmpty) {
      ZentraNotifier.warning(
        "Nothing to copy",
        "Receiver details are still loading — please try again.",
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: value));
    ZentraNotifier.success("Copied", "$label copied to clipboard.");
  }

  @override
  Widget build(BuildContext context) {
    // AppTheme.isTablet is width >= 600; keep the name honest so the maxWidth
    // branch below reads correctly (the old inverted check applied the 600px
    // cap to phones and full-bleed width to tablets).
    final bool isTablet = AppTheme.isTablet(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        maxWidth: isTablet ? MediaQuery.of(context).size.width : 600,
      ),
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
            Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: Text("Receive Money", style: AppTheme.headlineSmall),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return ListenableBuilder(
      listenable: Listenable.merge([
        WalletsRepository.instance,
        UserQRRepository.instance,
      ]),
      builder: (context, _) {
        final repo = WalletsRepository.instance;
        final userRepo = UserQRRepository.instance;

        // Comment: Show loading indicator while primary data resolves
        if ((repo.isLoading && !repo.isLoaded) ||
            (userRepo.isUserLoading && !userRepo.isUserLoaded)) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryPink),
          );
        }

        // Comment: Display error state if initial load failed
        if ((repo.error != null && !repo.isLoaded) ||
            (userRepo.userError != null && !userRepo.isUserLoaded)) {
          return EmptyStateWidget(
            icon: Icons.error_outline,
            message: "Could not load your accounts.",
            actionLabel: "Retry",
            onAction: () {
              repo.ensureLoaded().catchError((_) => null);
              userRepo.loadQRUserInfo().catchError((_) => null);
            },
          );
        }

        final accounts = [...repo.data?.fiatAccounts ?? []];
        if (accounts.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.account_balance_wallet_outlined,
            message: "No currency accounts yet — create a wallet first.",
          );
        }

        // Comment: Sort default account to top
        accounts.sort((a, b) {
          if (a.isDefault == b.isDefault) return 0;
          return a.isDefault ? -1 : 1;
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Details Card Header
              _buildUserSummaryHeader(userRepo),
              const SizedBox(height: AppTheme.spacingMd),

              // Wallet Cards with Pretty QR
              for (final account in accounts) ...[
                _buildAccountCard(account, userRepo),
                const SizedBox(height: AppTheme.spacingLg),
              ],
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        );
      },
    );
  }

  /// Displays user profile details fetched from UserQRRepository
  Widget _buildUserSummaryHeader(UserQRRepository userRepo) {
    // userData is null on first build (loadQRUserInfo is async) — never force
    // unwrap; a single `!` here used to crash the whole sheet before the
    // loading branch above could resolve.
    final info = userRepo.userData;
    final String userName = info == null
        ? "…"
        : "${info.firstName} ${info.lastName}".trim();
    final String displayName = userName.isEmpty ? "Your account" : userName;
    final String email = info?.email ?? '';

    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.brand.withAlpha(20),
            child: Icon(
              Icons.person_2_rounded,
              color: AppTheme.textBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: AppTheme.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (email.isNotEmpty)
                Text(
                  email,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(FiatAccount account, UserQRRepository userRepo) {
    final showQr = account.isDefault || _expanded.contains(account.accountId);

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
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
                            style: AppTheme.labelLarge,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (account.isDefault) ...[
                          const SizedBox(width: AppTheme.spacingSm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.textBlack.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                            child: const Text(
                              "Default",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.successGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      "${account.currencyCode} • ${account.zentag}",
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
                    color: AppTheme.textBlack,
                  ),
                  label: Text(
                    showQr ? "Hide QR" : "Show QR",
                    style: AppTheme.labelLarge.copyWith(color: AppTheme.brand),
                  ),
                ),
            ],
          ),
          if (showQr) ...[
            const SizedBox(height: AppTheme.spacingLg),

            // Comment: Pretty QR code container reuses the shared PrettyQrWidget
            // so the logo asset, H error correction and empty-data guard live
            // in exactly one place (generateQRCode.dart).
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                border: Border.all(
                  color: AppTheme.brand.withAlpha(20),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: PrettyQrWidget(qrData: _qrPayload(account, userRepo)),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _copy(account.zentag, "Zentag"),
                  icon: Icon(Icons.copy, size: 18, color: AppTheme.textBlack),
                  label: Text("Copy Zentag", style: AppTheme.labelSmall),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                TextButton.icon(
                  onPressed: () =>
                      _copy(_qrPayload(account, userRepo), "QR Payload"),
                  icon: Icon(Icons.copy, size: 18, color: AppTheme.textBlack),
                  label: Text("Copy Payload", style: AppTheme.labelSmall),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
