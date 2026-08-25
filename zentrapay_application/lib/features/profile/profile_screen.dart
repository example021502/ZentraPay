import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/repositories/profile_repository.dart';
import 'package:zentrapay_application/core/repositories/wallets_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/home/closeConfirmation.dart';
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
    // Each repository is a load-once cache (see CachedResource) — revisiting
    // this screen (a fresh push every time) reuses whatever was already
    // fetched instead of refetching.
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileRepository.instance.ensureLoaded();
      if (profile != null) {
        setState(() {
          userProfileData['firstName'] = profile.firstName;
          userProfileData['lastName'] = profile.lastName;
          userProfileData['primaryEmail'] = profile.email;
          userProfileData['phoneNumber'] = profile.phoneNumber;
          userProfileData['handle'] = '@${profile.zentag}';
          userProfileData['accountStatus'] = profile.status;
          userProfileData['accountType'] = profile.userType == 'MERCHANT'
              ? 'Merchant'
              : 'Individual';
          userProfileData['kycTier'] = 'Tier ${profile.kycTier}';
        });
      }
    } catch (_) {
      // Keep placeholder profile data on failure.
    }

    try {
      final profileDetails = await UserProfileDetailsRepository.instance
          .ensureLoaded();
      if (profileDetails != null) {
        setState(() {
          if (profileDetails.dateOfBirth != null) {
            userProfileData['dateOfBirth'] = profileDetails.dateOfBirth;
          }
          userProfileData['amlStatus'] = profileDetails.amlStatus;
          userProfileData['pepStatus'] = profileDetails.isPep
              ? 'Politically Exposed Person'
              : 'Not a Politically Exposed Person';
          final addressParts = [
            profileDetails.addressLine1,
            profileDetails.city,
            profileDetails.regionState,
          ].where((p) => p != null && p.isNotEmpty).join(', ');
          if (addressParts.isNotEmpty) {
            userProfileData['registeredAddress'] = addressParts;
          }
        });
      }
    } catch (_) {
      // KYC profile not filled in yet — keep placeholder.
    }

    // Business fields only apply to merchant accounts.
    if (userProfileData['accountType'] == 'Merchant') {
      try {
        final merchant = await MerchantProfileRepository.instance
            .ensureLoaded();
        if (merchant != null) {
          setState(() {
            userProfileData['businessLegalName'] = merchant.businessName;
            userProfileData['businessRegistrationNumber'] =
                merchant.businessRegistrationNumber ?? '';
            userProfileData['taxIdentificationNumber'] =
                merchant.taxIdentificationNumber ?? '';
          });
        }
      } catch (_) {
        // No merchant profile submitted yet.
      }
    }

    try {
      final snapshot = await WalletsRepository.instance.ensureLoaded();
      final fiatAccounts = snapshot?.fiatAccounts ?? [];
      if (fiatAccounts.isNotEmpty) {
        setState(() {
          accounts = fiatAccounts
              .map(
                (a) => {
                  'type': a.accountName,
                  'balance': a.balance,
                  'currency': a.currencyCode,
                  'accountNumber': a.zentag,
                  'ledgerId': a.accountId,
                  'status': a.status,
                },
              )
              .toList();
          currentWalletIndex = 0;
        });
      }
    } catch (_) {
      // Keep placeholder wallets on failure.
    }
  }

  final Map<String, dynamic> userProfileData = {
    'firstName': 'John',
    'lastName': 'Willis',
    'dateOfBirth': '1992-08-14',
    'nationality': 'Ghanaian',
    'gender': 'Male',

    'primaryEmail': 'john.willis@zentrapay.com',
    'secondaryEmail': 'j.willis.biz@gmail.com',
    'phoneNumber': '+233 24 123 4567',
    'secondaryPhoneNumber': '+254 712 345 678',
    'handle': '@johnwillis5623',
    'accountType': 'Corporate PSP Merchant',
    'accountStatus': 'Active / Verified',

    'kycTier': 'Tier 3 (Ultimate Corporate)',
    'businessLegalName': 'Willis Global Enterprises Ltd',
    'businessRegistrationNumber': 'CS-983482934',
    'taxIdentificationNumber': 'GHA-983482934-0001',
    'registeredAddress':
        '44 Liberation Road, Airport Residential, Accra, Ghana',
    'amlStatus': 'Cleared & Compliant',
    'pepStatus': 'Not a Politically Exposed Person',
    'defaultCorridor': 'GHS / USD / KES',
  };

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
        backgroundColor: AppColors.main,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profile",
          style: TextStyle(color: AppColors.primary),
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
            "${userProfileData['firstName'] ?? 'N/A'} ${userProfileData['lastName'] ?? 'N/A'}",
            style: AppTheme.displaySmall,
          ),
          const SizedBox(height: 2),
          Text(
            userProfileData['accountType'] ?? '',
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

  Widget _buildPersonalInformationSection() {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Personal Information", style: AppTheme.headlineSmall),
          const Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
          _buildInfoRow("First Name", userProfileData['firstName'] ?? ''),
          _buildInfoRow("Last Name", userProfileData['lastName'] ?? ''),
          _buildInfoRow("Date of Birth", userProfileData['dateOfBirth'] ?? ''),
          _buildInfoRow("Nationality", userProfileData['nationality'] ?? ''),
          _buildInfoRow("Gender", userProfileData['gender'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildAccountInformationSection() {
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Account Information", style: AppTheme.headlineSmall),
          const Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
          _buildInfoRow("Primary Email", userProfileData['primaryEmail'] ?? ''),
          _buildInfoRow(
            "Secondary Email",
            userProfileData['secondaryEmail'] ?? '',
          ),
          _buildInfoRow("Primary Phone", userProfileData['phoneNumber'] ?? ''),
          _buildInfoRow(
            "Secondary Phone",
            userProfileData['secondaryPhoneNumber'] ?? '',
          ),
          _buildInfoRow("Account Handle", userProfileData['handle'] ?? ''),
          _buildInfoRow(
            "Account Status",
            userProfileData['accountStatus'] ?? '',
          ),
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
                  userProfileData['amlStatus'] ?? '',
                  style: AppTheme.labelSmall.copyWith(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppTheme.spacingXl, color: AppTheme.gray100),
          _buildInfoRow("KYC Level", userProfileData['kycTier'] ?? ''),
          _buildInfoRow(
            "Legal Business Name",
            userProfileData['businessLegalName'] ?? '',
          ),
          _buildInfoRow(
            "Registration Number",
            userProfileData['businessRegistrationNumber'] ?? '',
          ),
          _buildInfoRow(
            "Tax ID (TIN)",
            userProfileData['taxIdentificationNumber'] ?? '',
          ),
          _buildInfoRow(
            "Registered Address",
            userProfileData['registeredAddress'] ?? '',
          ),
          _buildInfoRow("PEP Screening", userProfileData['pepStatus'] ?? ''),
          _buildInfoRow(
            "Active Corridors",
            userProfileData['defaultCorridor'] ?? '',
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
          const Text("Primary Treasury Node", style: AppTheme.headlineSmall),
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
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryNavy,
              ),
              child: const Text("Request Cross-Border Payment"),
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
          const Text("Dynamic Settlement QR", style: AppTheme.headlineSmall),
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
