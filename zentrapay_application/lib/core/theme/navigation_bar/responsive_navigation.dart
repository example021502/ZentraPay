import 'package:flutter/material.dart';
import 'package:paystack_flutter_sdk/paystack_flutter_sdk.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/navigation_bar/navigation_bar_main.dart';
import 'package:zentrapay_application/features/Settings/settings.dart';
import 'package:zentrapay_application/features/home/closeConfirmation.dart';
import 'package:zentrapay_application/features/home/home_wallet_main.dart';
import 'package:zentrapay_application/features/zbanking/zbanking_screen.dart';
import 'package:zentrapay_application/features/zgrow/zgrow_screen.dart';
import 'package:zentrapay_application/features/zremit/zremit_screen.dart';
import 'package:zentrapay_application/main.dart';

class ResponsiveNavigation extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ResponsiveNavigation({super.key, required this.userData});

  @override
  State<ResponsiveNavigation> createState() => _ResponsiveNavigationState();
}

class _ResponsiveNavigationState extends State<ResponsiveNavigation> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 5 tabs: Home, Remit, Grow, Bank, Merchant.
  // ZPay's card visuals were merged into Home; ZInvest is reached from
  // Grow; ZVoice/Secure are folded into Home's "More" access — see
  // _showMoreSheet(). Merchant is a placeholder pending content.
  final List<Widget> _pages = [
    const HomeWalletMain(),
    const ZRemitScreen(),
    const ZGrowScreen(),
    const ZBankingScreen(),
    const Settings(),
  ];

  // Create a local class property for Paystack
  final Paystack _paystack = Paystack();

  @override
  void initState() {
    super.initState();
    _initializePaystack();
  }

  // Handle the async initialization properly
  Future<void> _initializePaystack() async {
    try {
      // The official SDK accepts your public key and a boolean for logging
      bool isInitialized = await _paystack.initialize(
        "pk_test_your_public_key_here",
        true,
      );
      if (isInitialized) {
        debugPrint("Successfully initialized the Paystack SDK");
      }
    } catch (e) {
      debugPrint("Initialization error: $e");
    }
  }

  bool get _isTablet => MediaQuery.of(context).size.width >= 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.main,
      // Extend body behind bottom navigation bar
      extendBody: true,
      // Show drawer only on tablet screens
      drawer: _isTablet ? _buildDrawer() : null,
      // Show app bar only on mobile
      appBar: _isTablet ? null : _buildAppBar(),
      // Show bottom nav only on mobile
      bottomNavigationBar: _isTablet ? null : _buildBottomNav(),
      // IndexedStack keeps all four tabs mounted and alive at once, only
      // toggling visibility — so each tab's initState()/data-fetch runs once
      // per app session instead of re-running (and re-fetching) every time
      // the user switches back to it.
      body: IndexedStack(index: _selectedIndex, children: _pages),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.main,
      leading: _buildProfileIcon(),
      title: _buildGreeting(),
      actions: _buildActions(),
    );
  }

  Widget _buildProfileIcon() => IconButton(
    onPressed: () {
      if (_isTablet) {
        // On tablet, navigate to profile
        Navigator.pushNamed(context, '/profile');
      } else {
        // On mobile, could show a menu or navigate
        Navigator.pushNamed(context, '/profile');
      }
    },
    icon: Container(
      width: 40,
      height: 40,
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Center(child: Icon(Icons.person, color: AppColors.main)),
    ),
  );

  Widget _buildGreeting() {
    final name = widget.userData["full_name"] ?? "Welcome to ZentraPay";
    final email = widget.userData["email"] ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(
          email,
          style: const TextStyle(fontSize: 14, color: AppColors.primary),
        ),
      ],
    );
  }

  List<Widget> _buildActions() => [
    IconButton(
      onPressed: _showMoreSheet,
      icon: const Icon(Icons.apps, color: AppColors.primary),
      tooltip: 'More',
    ),
    IconButton(
      onPressed: () {},
      icon: const Icon(Icons.notifications, color: AppColors.primary),
    ),
    IconButton(
      onPressed: () async {
        bool isConfirm = await showCloseConfirmationDialog(context);
        if (!mounted) return;
        isConfirm ? Navigator.pushReplacementNamed(context, "/login") : null;
      },
      icon: const Icon(Icons.logout, color: AppColors.primary),
    ),
  ];

  // ZVoice AI and Secure don't have a dedicated bottom tab, so this gives
  // mobile users the same one-tap reach the tablet drawer already has.
  // ZBank Lite now has its own "Bank" tab and ZInvest is reached from Grow,
  // so neither needs a spot here anymore.
  void _showMoreSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.primaryWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMoreItem(Icons.mic, "ZVoice AI", '/zvoice'),
              _buildMoreItem(Icons.security, "Secure", '/secure'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreItem(IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.main),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _buildBottomNav() {
    return NavigationBarMain(
      selectedIndex: _selectedIndex,
      onItemSelected: (i) => setState(() => _selectedIndex = i),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        color: AppColors.primary,
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home,
                    label: "Home",
                    isSelected: _selectedIndex == 0,
                    onTap: () {
                      setState(() => _selectedIndex = 0);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.compare_arrows,
                    label: "Remit",
                    isSelected: _selectedIndex == 1,
                    onTap: () {
                      setState(() => _selectedIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.trending_up,
                    label: "Grow",
                    isSelected: _selectedIndex == 2,
                    onTap: () {
                      setState(() => _selectedIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance,
                    label: "Bank",
                    isSelected: _selectedIndex == 3,
                    onTap: () {
                      setState(() => _selectedIndex = 3);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.storefront,
                    label: "Merchant",
                    isSelected: _selectedIndex == 4,
                    onTap: () {
                      setState(() => _selectedIndex = 4);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.mic,
                    label: "ZVoice AI",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/zvoice');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.security,
                    label: "Secure",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/secure');
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.person,
                    label: "Profile",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    label: "Settings",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.currency_exchange,
                    label: "Converter",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/converter');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.track_changes,
                    label: "Milestones",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/milestones');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.smart_toy,
                    label: "AI Assistant",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/ai_assistance');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet,
                    label: "Liquidity Hub",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/liquidity_hub');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.mic,
                    label: "Voice Recording",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/voice_recording');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.security,
                    label: "Fraud Detection",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/fraud_detection');
                    },
                  ),
                ],
              ),
            ),
            _buildDrawerFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final name = widget.userData["full_name"] ?? "Welcome to ZentraPay";
    final email = widget.userData["email"] ?? "";

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: const BoxDecoration(
        color: AppColors.main,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: AppColors.main),
          ),
          const SizedBox(height: 15),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            style: const TextStyle(fontSize: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.main.withAlpha(25) : Colors.transparent,
          border: isSelected
              ? Border(left: BorderSide(color: AppColors.main, width: 4))
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.main : AppColors.textBlack,
              size: 24,
            ),
            const SizedBox(width: 20),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.main : AppColors.textBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.main.withAlpha(25),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: InkWell(
        onTap: () async {
          Navigator.pop(context);
          bool isConfirm = await showCloseConfirmationDialog(context);
          if (!mounted) return;
          if (isConfirm) {
            Navigator.pushReplacementNamed(context, "/login");
          }
        },
        child: Row(
          children: [
            Icon(Icons.logout, color: AppColors.main, size: 24),
            const SizedBox(width: 20),
            Text(
              "Logout",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.main,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
