import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/user.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profileData.dart';
import 'package:zentrapay_application/features/home/repository/cache_homeData.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbankingData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/profile/edit_profile_sheet.dart';
import 'package:zentrapay_application/main.dart';

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
      ]);
    } catch (e) {
      // Comment: Log error on failure without breaking screen UI render
      debugPrint("Profile screen initial load failed: $e");
    }
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

        return Scaffold(
          backgroundColor: AppTheme.gray50,
          appBar: AppBar(
            backgroundColor: AppTheme.gray50,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textBlack,
                size: 22,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: AppTheme.spacingLg),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                  ),
                  child: Column(
                    children: [
                      _buildPrimaryWallet(accounts),
                      const SizedBox(height: AppTheme.spacingLg),
                      _buildQRCodeSection(),
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
        );
      },
    );
  }

  Widget _buildProfileHeader(AppUser? user) {
    final String fullName = "${user?.firstName} ${user?.lastName}";
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
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: AppTheme.primaryWhite,
                ),
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
                    color: AppTheme.primaryWhite,
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
                color: AppTheme.secondaryNavy,
                decoration: TextDecoration.underline,
                decorationColor: AppTheme.secondaryNavy,
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
          const Text("Personal Information", style: AppTheme.labelLarge),
          const Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
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
          const Text("Profile Information", style: AppTheme.labelLarge),
          const Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
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
        color: AppTheme.primaryWhite,
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
              const Expanded(
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
          const Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
          _buildInfoRow("KYC Status", profile?.KYCStatus ?? ''),
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

  Widget _buildPrimaryWallet(List<Map<String, dynamic>> accounts) {
    final account = accounts.firstWhere(
      (a) => a['isDefault'] == true,
      orElse: () => <String, dynamic>{},
    );
    Map<String, dynamic> activeAccount = {};
    if (account.isNotEmpty) {
      activeAccount = account;
    }

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Primary Treasury Node", style: AppTheme.labelLarge),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Primary Account:",
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
              ),
              Text(
                activeAccount['accountName'] ?? 'No active account',
                style: AppTheme.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  activeAccount['accountNumber'] ?? '',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: activeAccount['accountNumber'] ?? ''),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Virtual account handle copied to clipboard',
                      ),
                    ),
                  );
                },
                child: const Text("Copy"),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          InkWell(
            onTap: () => showComingSoon(context, "Request payment"),
            child: Container(
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: AppTheme.secondaryNavy,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Center(
                  child: Text(
                    "Request Payment",
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.primaryWhite,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Dynamic Settlement QR", style: AppTheme.labelLarge),
          const SizedBox(height: AppTheme.spacingLg),
          Center(
            child: Container(
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
          ),
          const SizedBox(height: AppTheme.spacingMd),
          const Text("Broadcast Invoice:", style: AppTheme.labelLarge),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildShareIcon(Icons.message, "WhatsApp"),
              _buildShareIcon(Icons.email, "Gmail"),
              _buildShareIcon(Icons.chat, "Messenger"),
              _buildShareIcon(Icons.more_horiz, "More"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareIcon(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, color: AppTheme.gray700, size: 24),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          label,
          style: AppTheme.labelSmall.copyWith(color: AppTheme.gray500),
        ),
      ],
    );
  }

  Widget _buildWalletCarousel(List<Map<String, dynamic>> accounts) {
    if (accounts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              color: AppTheme.primaryWhite,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                "No wallet yet — create one from the Wallets tab to get started.",
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryWhite,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final currentWallet = accounts[accountIndex];

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentWallet['type'] ?? '',
                style: AppTheme.headlineSmall.copyWith(
                  color: AppTheme.primaryWhite,
                ),
              ),
              const Icon(
                Icons.account_balance_wallet,
                color: AppTheme.primaryWhite,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            "Ledger ID: ${currentWallet['ledgerId']}",
            style: AppTheme.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Text(
            "Available Liquidity",
            style: AppTheme.bodyMedium.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBalanceVisible
                    ? "${currentWallet['currency'] ?? ''} ${currentWallet['balance'] ?? ''}"
                    : "••••••••",
                style: AppTheme.displaySmall.copyWith(
                  color: AppTheme.primaryWhite,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    isBalanceVisible = !isBalanceVisible;
                  });
                },
                icon: Icon(
                  isBalanceVisible ? Icons.visibility : Icons.visibility_off,
                  color: AppTheme.primaryWhite,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    accountIndex =
                        (accountIndex - 1 + accounts.length) % accounts.length;
                  });
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppTheme.primaryWhite,
                ),
              ),
              Row(
                children: List.generate(accounts.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == accountIndex
                          ? AppTheme.primaryWhite
                          : AppTheme.primaryWhite.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    accountIndex = (accountIndex + 1) % accounts.length;
                  });
                },
                icon: const Icon(
                  Icons.arrow_forward,
                  color: AppTheme.primaryWhite,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccounts() {
    final accounts = BankAccountsRepository.instance.data ?? [];
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Linked Settlement Accounts", style: AppTheme.labelLarge),
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
                _formatDate(account.createdAt),
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
                  color: AppTheme.gray700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
