import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/user.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profile_data.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/features/home/generate_qr_code.dart';
import 'package:zentrapay_application/features/home/receive_sheet.dart';
import 'package:zentrapay_application/features/profile/edit_profile_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int accountIndex = 0;
  bool isBalanceVisible = false;

  @override
  void initState() {
    super.initState();
    // Comment: Trigger data loading when the screen mounts
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Comment: Ensure every repository this screen renders loads its
      // initial data from network/cache. Linked bank accounts reuse
      // BankAccountsRepository (already backend-wired for ZBanking) instead
      // of a screen-local fake list, so there's one source of truth.
      await Future.wait([
        UserProfileRepository.instance.ensureLoaded(),
        WalletsRepository.instance.ensureLoaded(),
        BankAccountsRepository.instance.ensureLoaded(),
        UserQRRepository.instance.loadQRUserInfo(),
      ]);
    } catch (e) {
      // Comment: Log error on failure without breaking screen UI render
      debugPrint("Profile screen initial load failed: $e");
    }
  }

  /// Pull-to-refresh: reloads everything this screen shows.
  Future<void> _refresh() async {
    try {
      await Future.wait([
        UserProfileRepository.instance.refresh(),
        WalletsRepository.instance.refresh(),
        BankAccountsRepository.instance.refresh(),
        UserQRRepository.instance.loadUserInfo(),
      ]);
    } catch (e) {
      debugPrint("Profile refresh failed: $e");
    }
  }

  /// The wallet the QR code and account details are shown for: the default
  /// fiat account, or the first one when none is flagged.
  FiatAccount? _primaryAccount(List<FiatAccount> accounts) {
    if (accounts.isEmpty) return null;
    return accounts.firstWhere(
      (a) => a.isDefault,
      orElse: () => accounts.first,
    );
  }

  /// Formats model dates for the info rows; empty string when null
  String _formatDate(DateTime? value) =>
      value == null ? '' : DateFormat('MMMM dd, yyyy').format(value.toLocal());

  /// Formats ISO-8601 strings
  String _formatDateString(String? value) => value == null || value.isEmpty
      ? ''
      : _formatDate(DateTime.tryParse(value));

  @override
  Widget build(BuildContext context) {
    // Comment: Rebuild automatically when any of the three repositories
    // this screen renders notifies changes.
    return ListenableBuilder(
      listenable: Listenable.merge([
        UserProfileRepository.instance,
        WalletsRepository.instance,
        BankAccountsRepository.instance,
        UserQRRepository.instance,
      ]),
      builder: (context, child) {
        final userRepo = UserProfileRepository.instance;
        final walletRepo = WalletsRepository.instance;

        final user = userRepo.user;
        final profile = userRepo.profile;
        final fiatAccounts = walletRepo.data?.fiatAccounts ?? [];

        // Comment: Map raw fiat accounts into carousel representation — no
        // fake fallback entry; an empty list is handled explicitly by
        // _buildWalletCarousel/_buildPrimaryWallet as a real empty state.
        // Explicitly typed (both the list and each map literal): mixing a
        // bool ('isDefault') in with the String fields shifts Dart's
        // inferred literal type from Map<String, dynamic> to
        // Map<String, Object> unless pinned down, which crashes
        // _buildPrimaryWallet's firstWhere(orElse: () => <String, dynamic>{})
        // at runtime ("type '() => Map<String, dynamic>' is not a subtype
        // of type '(() => Map<String, Object>)?' of 'orElse'").
        final List<Map<String, dynamic>> accounts = [
          for (final account in fiatAccounts)
            <String, dynamic>{
              'type': account.accountName.isNotEmpty
                  ? account.accountName
                  : '${account.currencyCode} Wallet',
              'balance': formatMoney(account.balance.toStringAsFixed(2)),
              'currency': account.currencyCode,
              'accountNumber': account.zentag,
              'ledgerId': account.accountId,
              'status': account.status,
              'isDefault': account.isDefault,
            },
        ];

        // Comment: Keep index in bounds if accounts list size changes dynamically
        if (accountIndex >= accounts.length) {
          accountIndex = 0;
        }

        final session = SecureStorageService.getSession();
        final fullName = [
          (user?.firstName.isNotEmpty ?? false)
              ? user!.firstName
              : session['firstName'],
          (user?.lastName.isNotEmpty ?? false)
              ? user!.lastName
              : session['lastName'],
        ].where((p) => p != null && p.isNotEmpty).join(' ');

        return Scaffold(
          backgroundColor: AppTheme.gray50,
          body: Column(
            children: [
              SectionHeader(
                title: "Profile",
                subtitle: fullName,
                icon: Icons.person_rounded,
                showBack: true,
                sheetColor: AppTheme.gray50,
              ),
              Expanded(
                child: RefreshIndicator(
                  color: AppTheme.primaryPink,
                  backgroundColor: AppTheme.surface,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        _buildProfileHeader(user),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingLg,
                          ),
                          child: Column(
                            children: [
                              _buildPrimaryAccountQr(
                                _primaryAccount(fiatAccounts),
                              ),
                              const SizedBox(height: AppTheme.spacingLg),
                              _buildWalletCarousel(accounts),
                              const SizedBox(height: AppTheme.spacingLg),
                              _buildBankAccounts(),
                              const SizedBox(height: AppTheme.spacingXl),
                              _buildPersonalInformationSection(user),
                              const SizedBox(height: AppTheme.spacingLg),
                              _buildProfileInformationSection(profile),
                              const SizedBox(height: AppTheme.spacingLg),
                              _buildComplianceSection(profile),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXl),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(AppUser? user) {
    // Until /api/users/me has loaded, fall back to the name in the signed-in
    // token so the header never reads "null null".
    final session = SecureStorageService.getSession();
    final String fullName = [
      (user?.firstName.isNotEmpty ?? false)
          ? user!.firstName
          : session['firstName'],
      (user?.lastName.isNotEmpty ?? false)
          ? user!.lastName
          : session['lastName'],
    ].where((p) => p != null && p.isNotEmpty).join(' ');
    final bool canTransact = user?.canTransact ?? false;
    final int tier = user?.kycTier ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingLg,
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryPink,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, size: 60, color: AppTheme.textBlack),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: canTransact
                        ? AppTheme.successGreen
                        : AppTheme.warningOrange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    canTransact ? Icons.check : Icons.priority_high,
                    size: 16,
                    color: AppTheme.textBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(fullName, style: AppTheme.displaySmall),
          const SizedBox(height: 2),
          Text(
            user?.userType ?? '',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          GestureDetector(
            onTap: () {
              if (canTransact) return;
              showEditProfileSheet(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: canTransact
                    ? AppTheme.successGreen.withValues(alpha: 0.12)
                    : AppTheme.warningOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                canTransact
                    ? "Tier $tier — verified"
                    : "Tier $tier — tap to upgrade & send money",
                style: AppTheme.labelSmall.copyWith(
                  color: canTransact
                      ? AppTheme.successGreen
                      : AppTheme.warningOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          GestureDetector(
            onTap: () => showEditProfileSheet(context),
            child: Text(
              "Edit Profile",
              style: AppTheme.labelLarge.copyWith(
                color: AppTheme.brand,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformationSection(AppUser? user) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text("Personal Information", style: AppTheme.labelLarge),
          Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
          _buildInfoRow("User ID", user?.userId ?? ''),
          _buildInfoRow("First Name", user?.firstName ?? ''),
          _buildInfoRow("Last Name", user?.lastName ?? ''),
          _buildInfoRow("Email", user?.email ?? ''),
          _buildInfoRow("Phone Number", user?.phoneNumber ?? ''),
          _buildInfoRow("Country Code", user?.countryCode ?? ''),
          _buildInfoRow("Account Type", user?.userType ?? ''),
          _buildInfoRow("Account Status", user?.status ?? ''),
          _buildInfoRow("Member Since", _formatDateString(user?.createdAt)),
        ],
      ),
    );
  }

  Widget _buildProfileInformationSection(UserProfile? profile) {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Profile Information", style: AppTheme.labelLarge),
          Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
          _buildInfoRow("Date of Birth", _formatDate(profile?.dateOfBirth)),
          _buildInfoRow("Nationality", profile?.nationalityCountryCode ?? ''),
          _buildInfoRow("Occupation", profile?.occupationTitle ?? ''),
          _buildInfoRow(
            "Identity Document Type",
            profile?.identityDocumentType ?? '',
          ),
          _buildInfoRow(
            "Identity Document Number",
            profile?.identityDocumentNumber ?? '',
          ),
          _buildInfoRow(
            "Issuing Country",
            profile?.identityDocumentIssuingCountryCode ?? '',
          ),
          _buildInfoRow(
            "Document Expiration",
            _formatDate(profile?.identityDocumentExpirationDate),
          ),
          _buildInfoRow("Address Line 1", profile?.addressLine1 ?? ''),
          _buildInfoRow("Address Line 2", profile?.addressLine2 ?? ''),
          _buildInfoRow("City", profile?.cityName ?? ''),
          _buildInfoRow("State / Region", profile?.stateOrRegion ?? ''),
          _buildInfoRow("Postal Code", profile?.postalCode ?? ''),
          _buildInfoRow("Profile Created", _formatDate(profile?.createdAt)),
          _buildInfoRow("Last Updated", _formatDate(profile?.updatedAt)),
        ],
      ),
    );
  }

  Widget _buildComplianceSection(UserProfile? profile) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text("Compliance & Risk", style: AppTheme.labelLarge),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  profile?.antiMoneyLaunderingStatus ?? '',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
          _buildInfoRow("KYC Status", profile?.kycStatus ?? ''),
          _buildInfoRow("AML Status", profile?.antiMoneyLaunderingStatus ?? ''),
          _buildInfoRow(
            "PEP Screening",
            profile == null
                ? ''
                : (profile.isPoliticallyExposedPerson ? 'Yes' : 'No'),
          ),
          _buildInfoRow("Risk Score Level", profile?.riskScoreLevel ?? ''),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Flexible(
            child: Text(
              value,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.labelLarge,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// The primary account's receive QR - the same code the Receive sheet shows -
  /// with the account's details underneath.
  Widget _buildPrimaryAccountQr(FiatAccount? account) {
    if (account == null) {
      return AppCard(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Row(
          children: [
            Icon(Icons.qr_code_2, color: AppTheme.textBlack, size: 32),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Text(
                "No wallet yet - your primary account QR will appear here "
                "once you have one.",
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
              ),
            ),
          ],
        ),
      );
    }

    final qrRepo = UserQRRepository.instance;
    final payload = buildAccountQrPayload(account, qrRepo.userData);
    final active = account.status.toUpperCase() == 'ACTIVE';
    final tone = active ? AppTheme.successGreen : AppTheme.warningOrange;
    final name = account.accountName.isNotEmpty
        ? account.accountName
        : '${account.currencyCode} Wallet';

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("Receive money", style: AppTheme.labelLarge),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.brand.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Text(
                  "Primary account",
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.brand,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            "Anyone can scan this code to pay your ${account.currencyCode} account.",
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Center(
            child: qrRepo.isUserLoading && payload.isEmpty
                ? SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryPink,
                      ),
                    ),
                  )
                : PrettyQrWidget(qrData: payload),
          ),
          if (payload.isEmpty && !qrRepo.isUserLoading) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Center(
              child: TextButton(
                onPressed: _refresh,
                child: const Text("Could not load the QR code - tap to retry"),
              ),
            ),
          ],
          Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
          _buildInfoRow("Account name", name),
          _buildInfoRow("Zentag", account.zentag),
          _buildInfoRow("Currency", account.currencyCode),
          _buildInfoRow("Account ID", account.accountId),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
            child: Row(
              children: [
                Text(
                  "Status",
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tone,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  account.status,
                  style: AppTheme.labelLarge.copyWith(color: tone),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: "Copy Zentag",
                  onPressed: () => _copy(account.zentag, "Zentag"),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: SecondaryButton(
                  label: "Copy account ID",
                  onPressed: () => _copy(account.accountId, "Account ID"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copy(String value, String label) {
    if (value.trim().isEmpty) {
      ZentraNotifier.warning(
        "Nothing to copy",
        "Account details are still loading - please try again.",
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: value));
    ZentraNotifier.success("Copied", "$label copied to clipboard.");
  }

  Widget _buildWalletCarousel(List<Map<String, dynamic>> accounts) {
    if (accounts.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: AppTheme.textBlack,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                "No wallet yet - create one from the Wallets tab to get started.",
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
              ),
            ),
          ],
        ),
      );
    }

    final currentWallet = accounts[accountIndex];
    final multiple = accounts.length > 1;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  currentWallet['type'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelLarge,
                ),
              ),
              if (currentWallet['isDefault'] == true)
                Text(
                  "Default",
                  style: AppTheme.labelSmall.copyWith(color: AppTheme.brand),
                ),
              const SizedBox(width: AppTheme.spacingSm),
              Icon(Icons.account_balance_wallet, color: AppTheme.textBlack),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            "Ledger ID: ${currentWallet['ledgerId']}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
          Text(
            "Available balance",
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            children: [
              Expanded(
                child: Text(
                  isBalanceVisible
                      ? "${currentWallet['currency'] ?? ''} ${currentWallet['balance'] ?? ''}"
                      : "••••••••",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.displaySmall,
                ),
              ),
              IconButton(
                onPressed: () =>
                    setState(() => isBalanceVisible = !isBalanceVisible),
                icon: Icon(
                  isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.textBlack,
                ),
              ),
            ],
          ),
          if (multiple) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    accountIndex =
                        (accountIndex - 1 + accounts.length) % accounts.length;
                  }),
                  icon: Icon(Icons.arrow_back, color: AppTheme.textBlack),
                ),
                Row(
                  children: List.generate(accounts.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: index == accountIndex
                            ? AppTheme.brand
                            : AppTheme.gray300,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    accountIndex = (accountIndex + 1) % accounts.length;
                  }),
                  icon: Icon(Icons.arrow_forward, color: AppTheme.textBlack),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBankAccounts() {
    // `data` is a snapshot (primary + accounts); the settlement list wants
    // every linked account.
    final accounts = BankAccountsRepository.instance.accounts;
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Linked Settlement Accounts", style: AppTheme.labelLarge),
          const SizedBox(height: AppTheme.spacingMd),
          if (accounts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              child: Text(
                "No linked bank accounts yet.",
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
              ),
            )
          else
            ...accounts.map((account) => _buildBankCard(account)),
        ],
      ),
    );
  }

  Widget _buildBankCard(BankAccounts account) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.gray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(account.bankName, style: AppTheme.headlineSmall),
              Text(
                _formatDate(account.linkedAt),
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            "•••• ${account.lastDigits}",
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBalanceVisible
                    ? "${account.currencyCode} ${account.balance.toStringAsFixed(2)}"
                    : "••••••••",
                style: AppTheme.displaySmall,
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    isBalanceVisible = !isBalanceVisible;
                  });
                },
                icon: Icon(
                  isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.textBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
