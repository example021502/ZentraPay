import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/zremit/widgets/RecentSends.dart';

import 'widgets/zremit_header.dart';

class ZRemitScreen extends StatelessWidget {
  const ZRemitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final maxWidth = isTablet ? 800.0 : double.infinity;
    final horizontalPadding = isTablet ? 40.0 : 15.0;
    final bottomPadding = isTablet ? 40.0 : 120.0;
    TextEditingController searchController = TextEditingController();

    return Container(
      color: AppColors.primary,
      height: MediaQuery.of(context).size.height,
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
      child: SingleChildScrollView(
        child: Column(
          spacing: 30,
          children: [
            _searchBar(searchController),
            const ZRemitHeader(title: "Send Money Around the Globe"),
            _quickRemitOptions(context),
            RecentSends(),
            // SendingForm(),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(TextEditingController controller) => TextField(
    controller: controller,
    decoration: InputDecoration(
      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      prefixIcon: const Icon(Icons.search, size: 20),
      hintText: "Search Recipient...",
      border: InputBorder.none,
      filled: true,
      fillColor: AppColors.lightGrey.withAlpha(40),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.main, width: 1),
        borderRadius: BorderRadius.circular(200),
      ),

      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: AppColors.lightGrey, width: 1),
        borderRadius: BorderRadius.circular(200),
      ),
    ),
  );

  Widget _quickRemitOptions(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      _buildQuickOption(
        context,
        Icons.person_add,
        "New Contact",
        () => _showComingSoon(context, "New Contact"),
      ),
      _buildQuickOption(context, Icons.account_balance, "To Bank", () {
        Navigator.pushNamed(
          context,
          '/external_payment',
          arguments: {'token': 'user_token_here', 'userData': {}},
        );
      }),
      _buildQuickOption(
        context,
        Icons.qr_code_scanner,
        "Scan QR",
        () => _showComingSoon(context, "QR Scanner"),
      ),
      _buildQuickOption(
        context,
        Icons.history,
        "History",
        () => _showComingSoon(context, "Transaction History"),
      ),
    ],
  );

  Widget _buildQuickOption(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.main.withAlpha(25),
          child: Icon(icon, color: AppColors.main, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: AppColors.main,
      ),
    );
  }
}
