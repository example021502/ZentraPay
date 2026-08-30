import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/user.dart';
import 'package:zentrapay_application/core/repositories/user_profile_repository.dart';
import 'package:zentrapay_application/core/repositories/wallets_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/common/loadingScreen.dart';
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
      // Comment: Ensure both repositories load their initial data from network/cache
      await Future.wait([
        UserProfileRepository.instance.ensureLoaded(),
        WalletsRepository.instance.ensureLoaded(),
      ]);
      print("DATA LOADED!");
    } catch (e) {
      // Comment: Log error on failure without breaking screen UI render
      print("USERPROFILE:: load failed: $e");
    }
  }

  /// Formats model dates for the info rows; empty string when null
  String _formatDate(DateTime? value) =>
      value == null ? '' : DateFormat('MMMM dd, yyyy').format(value.toLocal());

  /// Formats ISO-8601 strings
  String _formatDateString(String? value) => value == null || value.isEmpty
      ? ''
      : _formatDate(DateTime.tryParse(value));

  final List<Map<String, dynamic>> bankAccounts = [
    {
      'name': 'Ecobank Ghana PLC',
      'accountNumber': '•••• 4092',
      'date': 'June 06, 2026',
      'rate': '+14.5% Yield',
      'balance': '1,250.00',
      'swiftCode': 'ECOGHACXXX',
    },
    {
      'name': 'Equity Bank Kenya',
      'accountNumber': '•••• 8821',
      'date': 'January 15, 2026',
      'rate': '+8.2% Yield',
      'balance': '4,100.00',
      'swiftCode': 'EQBLKENXXXX',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Comment: Rebuild automatically when either repository notifies changes
    return ListenableBuilder(
      listenable: Listenable.merge([
        UserProfileRepository.instance,
        WalletsRepository.instance,
      ]),
      builder: (context, child) {
        final userRepo = UserProfileRepository.instance;
        final walletRepo = WalletsRepository.instance;

        final user = userRepo.user;
        final profile = userRepo.profile;
        final fiatAccounts = walletRepo.data?.fiatAccounts ?? [];
        print("THE USER REPO:: $user AND PROFILE REPO IS:: $profile");

        // Comment: Map raw fiat accounts into carousel repSresentation
        final accounts = fiatAccounts.isNotEmpty
            ? [
                for (final account in fiatAccounts)
                  {
                    'type': account.accountName.isNotEmpty
                        ? account.accountName
                        : '${account.currencyCode} Wallet',
                    'balance': formatMoney(account.balance.toStringAsFixed(2)),
                    'currency': account.currencyCode,
                    'accountNumber': account.zentag,
                    'ledgerId': account.accountId,
                    'status': account.status,
                  },
              ]
            : [
                // Comment: Fallback placeholder when no fiat accounts exist
                {
                  'type': 'GHS Primary Wallet',
                  'balance': '4,500.50',
                  'currency': 'GHS',
                  'accountNumber': 'johnwillis5623.GHS@zentrapay',
                  'ledgerId': 'LEDGER_GHS_8832',
                  'status': 'Active',
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
                  decoration: const BoxDecoration(
                    color: AppTheme.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
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
            onTap: () => LoadingScreen(isLoading: true),
            child: Text(
              "Profile",
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          Flexible(
            child: Text(
              value,
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
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Linked Settlement Accounts", style: AppTheme.labelLarge),
          const SizedBox(height: AppTheme.spacingMd),
          ...bankAccounts.map((account) => _buildBankCard(account)),
        ],
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> account) {
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
              Text(
                "SWIFT: ${account['swiftCode']}",
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
              Text(
                account['date'] ?? '',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      size: 12,
                      color: AppTheme.primaryWhite,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      account['rate'] ?? '',
                      style: AppTheme.labelSmall.copyWith(
                        color: AppTheme.primaryWhite,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                account['accountNumber'] ?? '',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(account['name'] ?? '', style: AppTheme.headlineSmall),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBalanceVisible ? account['balance'] ?? '' : "••••••••",
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
