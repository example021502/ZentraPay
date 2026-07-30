import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int currentWalletIndex = 0;
  bool isBalanceVisible = false;

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

  final List<Map<String, dynamic>> wallets = [
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
      backgroundColor: AppColors.main,
      appBar: AppBar(
        backgroundColor: AppColors.main,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "PSP Complete Dossier",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: AppColors.green),
            onPressed: () => _showSecurityAuditModal(context),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildProfileHeader(),
                const SizedBox(height: 20),
                _buildPersonalInformationSection(),
                const SizedBox(height: 20),
                _buildAccountInformationSection(),
                const SizedBox(height: 20),
                _buildImportantBusinessSection(),
                const SizedBox(height: 20),
                _buildPrimaryWallet(),
                const SizedBox(height: 20),
                _buildQRCodeSection(),
                const SizedBox(height: 20),
                _buildWalletCarousel(),
                const SizedBox(height: 20),
                _buildBankAccounts(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.main,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "${userProfileData['firstName'] ?? 'N/A'} ${userProfileData['lastName'] ?? 'N/A'}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            userProfileData['handle'] ?? 'N/A',
            style: const TextStyle(fontSize: 13, color: AppColors.textBlack),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, size: 16, color: AppColors.green),
              const SizedBox(width: 4),
              Text(
                userProfileData['accountType'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformationSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Personal Information",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const Divider(height: 20),
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Account Information",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const Divider(height: 20),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.green.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Important Information & Compliance",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  userProfileData['amlStatus'] ?? '',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.green,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textBlack),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textBlack,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryWallet() {
    final activeWallet = wallets[currentWalletIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Primary Treasury Node",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Active Route:",
                style: TextStyle(fontSize: 14, color: AppColors.textBlack),
              ),
              Text(
                activeWallet['type'] ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  activeWallet['accountNumber'] ?? '',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textBlack,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Virtual account handle copied to clipboard',
                      ),
                    ),
                  );
                },
                child: const Text(
                  "Copy",
                  style: TextStyle(fontSize: 12, color: AppColors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Request Cross-Border Payment",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Dynamic Settlement QR",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.primary,
              border: Border.all(color: AppColors.textBlack, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.qr_code_2,
              size: 150,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: const Text(
              "Copy Settlement QR Payload",
              style: TextStyle(fontSize: 14, color: AppColors.green),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Broadcast Invoice:",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 12),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.main.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.textBlack, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textBlack),
        ),
      ],
    );
  }

  Widget _buildWalletCarousel() {
    final currentWallet = wallets[currentWalletIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.purple,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentWallet['type'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Ledger ID: ${currentWallet['ledgerId']}",
            style: const TextStyle(fontSize: 11, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          const Text(
            "Available Liquidity",
            style: TextStyle(fontSize: 14, color: AppColors.primary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBalanceVisible
                    ? "${currentWallet['currency'] ?? ''} ${currentWallet['balance'] ?? ''}"
                    : "••••••••",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
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
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    currentWalletIndex =
                        (currentWalletIndex - 1 + wallets.length) %
                        wallets.length;
                  });
                },
                icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              ),
              Row(
                children: List.generate(wallets.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == currentWalletIndex
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    currentWalletIndex =
                        (currentWalletIndex + 1) % wallets.length;
                  });
                },
                icon: const Icon(Icons.arrow_forward, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccounts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Linked Settlement Accounts",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          ...bankAccounts.map((account) => _buildBankCard(account)),
        ],
      ),
    );
  }

  Widget _buildBankCard(Map<String, dynamic> account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.main.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.main.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "SWIFT: ${account['swiftCode']}",
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textBlack,
                ),
              ),
              Text(
                account['date'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_upward,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      account['rate'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                account['accountNumber'] ?? '',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            account['name'] ?? '',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            // mainAxisAlignment: MainAxisAlignment.invisible,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isBalanceVisible ? account['balance'] ?? '' : "••••••••",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
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
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSecurityAuditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PSP Security & Audit Logs",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "• Two-Factor Authentication (2FA): Active\n• Device Fingerprint: Trusted (Android 14)\n• API Secret Key Rotated: 14 days ago\n• Transaction Velocity Limit: Optimal",
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textBlack,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Close Audit",
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
