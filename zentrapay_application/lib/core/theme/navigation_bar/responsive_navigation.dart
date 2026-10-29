import 'package:flutter/material.dart';
import 'package:paystack_flutter_sdk/paystack_flutter_sdk.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/core/theme/navigation_bar/navigation_bar_main.dart';
import 'package:zentrapay_application/core/utils/double_back_to_exit.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/core/utils/tab_switch_notifier.dart';
import 'package:zentrapay_application/features/Settings/settings.dart';
import 'package:zentrapay_application/features/home/close_confirmation.dart';
import 'package:zentrapay_application/features/home/home_wallet_main.dart';
import 'package:zentrapay_application/features/home/notifications_overlay.dart';
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
    NotificationsRepository.instance.ensureLoaded().catchError((_) => null);
    // A screen that isn't the navigation shell (e.g. ZBank's "Home" quick
    // action) calls TabSwitchNotifier.select(); mirror it into _selectedIndex
    // so the bar highlights the new tab as well as the body swapping.
    TabSwitchNotifier.instance.addListener(_onExternalTabRequest);
    _selectedIndex = TabSwitchNotifier.instance.current.tabIndex;
  }

  @override
  void dispose() {
    TabSwitchNotifier.instance.removeListener(_onExternalTabRequest);
    super.dispose();
  }

  void _onExternalTabRequest() {
    final next = TabSwitchNotifier.instance.current.tabIndex;
    if (!mounted || next == _selectedIndex) return;
    setState(() => _selectedIndex = next);
  }

  /// Single funnel for every tab change (bottom bar, drawer, external request)
  /// so the notifier and `_selectedIndex` can never drift apart.
  void _selectTab(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    TabSwitchNotifier.instance.select(AppTab.values[index]);
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

  /// A field of the signed-in user's identity. The saved session (written on
  /// login / register) wins; the JWT claims handed over by the splash screen
  /// are the fallback for a user who is already signed in from a previous run.
  String _identity(String key) {
    final saved = SecureStorageService.getSession()[key];
    if (saved != null && saved.isNotEmpty) return saved;
    return (widget.userData[key] ?? '').toString();
  }

  /// First back press from any tab but Home returns to Home instead of
  /// counting towards leaving the app.
  bool _backToHomeTab() {
    if (_selectedIndex == 0) return false;
    _selectTab(0);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBackToExit(
      onBack: _backToHomeTab,
      child: _buildShell(context),
    );
  }

  Widget _buildShell(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.headerPink,
      // Extend body behind bottom navigation bar
      extendBody: true,
      // Show drawer only on tablet screens
      drawer: _isTablet ? _buildDrawer() : null,
      // The user-information app bar belongs to Home alone. Every other
      // section draws its own titled SectionHeader, so no app bar here.
      appBar: (_isTablet || _selectedIndex != 0) ? null : _buildAppBar(),
      // Show bottom nav only on mobile
      bottomNavigationBar: _isTablet ? null : _buildBottomNav(),
      // IndexedStack keeps all four tabs mounted and alive at once, only
      // toggling visibility — so each tab's initState()/data-fetch runs once
      // per app session instead of re-running (and re-fetching) every time
      // the user switches back to it.
      body: IndexedStack(index: _selectedIndex, children: _pages),
    );
  }

  // Home is the only tab with an app bar: profile icon + fullname/email
  // greeting + notifications. Every other tab opens with its own titled
  // SectionHeader instead.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.headerPink,
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
      width: 50,
      height: 50,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person,
          color: AppTheme.isDark
              ? AppTheme.primaryWhite
              : AppTheme.secondaryNavy,
          size: 25,
        ),
      ),
    ),
  );

  Widget _buildGreeting() {
    final name = "${_identity("firstName")} ${_identity("lastName")}".trim();
    final email = _identity("email");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isNotEmpty ? name : "Welcome to Zentrapay",
          style: AppTheme.bodyLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (email.isNotEmpty)
          Text(
            email,
            style: AppTheme.bodySmall.copyWith(color: AppColors.primary),
          ),
      ],
    );
  }

  // Only notifications live on the AppBar now — the "More" overlay (apps
  // icon) moved to Home's own Quick Actions row (see HomeQuickActions'
  // _onMoreAction, which now also carries ZVoice AI and Settings/Security),
  // and the close/logout action moved into the Profile section.
  List<Widget> _buildActions() => [
    ListenableBuilder(
      listenable: NotificationsRepository.instance,
      builder: (context, _) {
        final unread = NotificationsRepository.instance.unreadCount;
        return IconButton(
          onPressed: () => showNotificationsOverlay(
            context,
            onUpgrade: () => Navigator.pushNamed(context, '/profile'),
          ),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text('$unread'),
            child: Icon(
              Icons.notifications,
              color: AppTheme.primaryWhite,
              size: 25,
            ),
          ),
        );
      },
    ),
  ];

  Widget _buildBottomNav() {
    return NavigationBarMain(
      selectedIndex: _selectedIndex,
      onItemSelected: _selectTab,
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      child: Container(
        color: AppTheme.surface,
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
                      _selectTab(0);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.compare_arrows,
                    label: "Remit",
                    isSelected: _selectedIndex == 1,
                    onTap: () {
                      _selectTab(1);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.trending_up,
                    label: "Grow",
                    isSelected: _selectedIndex == 2,
                    onTap: () {
                      _selectTab(2);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance,
                    label: "Bank",
                    isSelected: _selectedIndex == 3,
                    onTap: () {
                      _selectTab(3);
                      Navigator.pop(context);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings_outlined,
                    label: "Settings",
                    isSelected: _selectedIndex == 4,
                    onTap: () {
                      _selectTab(4);
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.mic,
                    label: "ZVoice AI",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/zvoice');
                    },
                  ),
                  // "Secure" is folded into Settings now (tab index 4,
                  // "Merchant" above) — no standalone destination left.
                  const Divider(),
                  _buildDrawerItem(
                    icon: Icons.person,
                    label: "Profile",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/profile');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    label: "Settings",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const Settings()),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.currency_exchange,
                    label: "Converter",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/converter');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.track_changes,
                    label: "Milestones",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/milestones');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.smart_toy,
                    label: "AI Assistant",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/ai_assistance');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet,
                    label: "Liquidity Hub",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/liquidity_hub');
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.security,
                    label: "Fraud Detection",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(
                        context,
                        '/fraud_detection',
                      );
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
    final fullName = "${_identity("firstName")} ${_identity("lastName")}"
        .trim();
    final name = fullName.isNotEmpty ? fullName : "Welcome to ZentraPay";
    final email = _identity("email");

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        color: AppTheme.headerPink,
        borderRadius: const BorderRadius.only(
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
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, size: 40, color: AppTheme.textBlack),
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
          if (isConfirm) {
            await SecureStorageService.deleteToken();
            await SecureStorageService.clearCustomer();
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(
              context,
              "/login",
              (route) => false,
            );
          }
        },
        child: Row(
          children: [
            Icon(Icons.logout, color: AppTheme.textBlack, size: 24),
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
