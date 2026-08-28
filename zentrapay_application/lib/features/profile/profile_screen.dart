import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/user.dart';
import 'package:zentrapay_application/core/repositories/user_profile_repository.dart';
import 'package:zentrapay_application/core/repositories/wallets_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int currentWalletIndex = 0;
  bool isBalanceVisible = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Null until UserProfileRepository.instance.ensureLoaded() resolves; the
  // info sections fall back to blank strings while loading or when the
  // fetch fails.
  AppUser? _user;
  UserProfile? _profile;

  Future<void> _loadProfile() async {
    try {
      // Both repositories are load-once caches (see CachedResource) —
      // revisiting this screen (a fresh push every time) reuses whatever
      // was already fetched instead of refetching.
      final snapshot = await UserProfileRepository.instance.ensureLoaded();

      await WalletsRepository.instance.ensureLoaded();
      final fiatAccounts = WalletsRepository.instance.data?.fiatAccounts ?? [];
      print(
        "USERPROFILE:: user=${snapshot?.user.fullName} "
        "(profile loaded: ${snapshot?.profile != null})",
      );
      if (!mounted) return;
      setState(() {
        _user = snapshot?.user;
        _profile = snapshot?.profile;
        // Real fiat balances replace the placeholder defaults below. The
        // placeholders are only kept when the wallet load failed/returned
        // nothing, so the carousel never renders empty.
        if (fiatAccounts.isNotEmpty) {
          accounts = [
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
          ];
          if (currentWalletIndex >= accounts.length) currentWalletIndex = 0;
        }
      });
    } catch (e) {
      // Keep placeholder profile data on failure — but log it, otherwise a
      // 401/network failure here is completely silent.
      print("USERPROFILE:: load failed: $e");
    }
  }

  /// Formats model dates (member since, DOB, KYC timestamps...) for the
  /// info rows; empty string when the field was never set.
  String _formatDate(DateTime? value) =>
      value == null ? '' : DateFormat('MMMM dd, yyyy').format(value.toLocal());

  // Placeholder default; replaced with real fiat balances in _loadProfile().
  List<Map<String, dynamic>> accounts = [
    {
      'type': 'GHS Primary Wallet',
      'balance': '4,500.50',
      'currency': 'GHS',
      'accountNumber': 'johnwillis5623.GHS@zentrapay',
      'ledgerId': 'LEDGER_GHS_8832',
      'status': 'Active',
    },
    {
      'type': 'USD Corporate Wallet',
      'balance': '350.00',
      'currency': 'USD',
      'accountNumber': 'johnwillis5623.USD@zentrapay',
      'ledgerId': 'LEDGER_USD_9941',
      'status': 'Active',
    },
    {
      'type': 'KES Regional Wallet',
      'balance': '12,800.00',
      'currency': 'KES',
      'accountNumber': 'johnwillis5623.KES@zentrapay',
      'ledgerId': 'LEDGER_KES_1102',
      'status': 'Active',
    },
  ];

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
            _buildProfileHeader(),
            const SizedBox(height: AppTheme.spacingLg),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLg,
              ),
              child: Column(
                children: [
                  _buildPrimaryWallet(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildQRCodeSection(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildWalletCarousel(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildBankAccounts(),
                  const SizedBox(height: AppTheme.spacingXl),
                  _buildPersonalInformationSection(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildAccountInformationSection(),
                  const SizedBox(height: AppTheme.spacingLg),
                  _buildImportantBusinessSection(),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  // No card/shadow/color wrapper here — sits directly on the screen's
  // AppTheme.gray50 background, per the reference layout.
  Widget _buildProfileHeader() {
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
          Text(
            (_user?.fullName.isNotEmpty ?? false) ? _user!.fullName : 'N/A',
            style: AppTheme.displaySmall,
          ),
          const SizedBox(height: 2),
          Text(
            _user?.userType ?? '',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          GestureDetector(
            onTap: () => showComingSoon(context, "Edit Profile"),
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

  /// Account record section — renders every field defined on [AppUser].
  Widget _buildPersonalInformationSection() {
    final user = _user;
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          _buildInfoRow("Member Since", _formatDate(user?.createdAt)),
        ],
      ),
    );
  }

  /// KYC profile record section — renders every field defined on
  /// [UserProfile] (identity document, address, occupation, timestamps).
  Widget _buildProfileInformationSection() {
    final profile = _profile;
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

  Widget _buildImportantBusinessSection() {
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
                child: Text(
                  "Important Information & Compliance",
                  style: AppTheme.headlineSmall,
                ),
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
                  _userInfoView['amlStatus'] ?? '',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
          _buildInfoRow("KYC Level", _userInfoView['kycTier'] ?? ''),
          _buildInfoRow(
            "Legal Business Name",
            _userInfoView['businessLegalName'] ?? '',
          ),
          _buildInfoRow(
            "Registration Number",
            _userInfoView['businessRegistrationNumber'] ?? '',
          ),
          _buildInfoRow(
            "Tax ID (TIN)",
            _userInfoView['taxIdentificationNumber'] ?? '',
          ),
          _buildInfoRow(
            "Registered Address",
            _userInfoView['registeredAddress'] ?? '',
          ),
          _buildInfoRow("PEP Screening", _userInfoView['pepStatus'] ?? ''),
          _buildInfoRow(
            "Active Corridors",
            _userInfoView['defaultCorridor'] ?? '',
          ),
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

  Widget _buildPrimaryWallet() {
    final activeWallet = accounts[currentWalletIndex];

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: const Text(
              "Primary Treasury Node",
              style: AppTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Active Route:",
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
              ),
              Text(activeWallet['type'] ?? '', style: AppTheme.labelLarge),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  activeWallet['accountNumber'] ?? '',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Actually copy the handle — the snackbar previously
                  // claimed a copy that never happened.
                  Clipboard.setData(
                    ClipboardData(text: activeWallet['accountNumber'] ?? ''),
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
        children: [
          const Text("Dynamic Settlement QR", style: AppTheme.bodyMedium),
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
          TextButton(
            onPressed: () {},
            child: const Text("Copy Settlement QR Payload"),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          const Text("Broadcast Invoice:", style: AppTheme.headlineSmall),
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

  Widget _buildWalletCarousel() {
    final currentWallet = accounts[currentWalletIndex];

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
                    currentWalletIndex =
                        (currentWalletIndex - 1 + accounts.length) %
                        accounts.length;
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
                      color: index == currentWalletIndex
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
                    currentWalletIndex =
                        (currentWalletIndex + 1) % accounts.length;
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
          const Text(
            "Linked Settlement Accounts",
            style: AppTheme.headlineSmall,
          ),
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
