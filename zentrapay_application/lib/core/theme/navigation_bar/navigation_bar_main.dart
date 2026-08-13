import 'package:curved_navigation_bar_pro/curved_navigation_bar_pro.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

/// Bottom navigation: icons only when inactive. The active tab's icon
/// sits inside a small navy chip nested in the bar's curved notch, and
/// its label sits below, centered on the navy bar surface (not inside
/// the curve itself). The notch is kept shallow — just enough to
/// separate the icon from its label. Home sits in the middle and is
/// active on launch.
///
/// [selectedIndex] / [onItemSelected] use the *semantic* tab index that
/// matches `ResponsiveNavigation._pages` (0 Home, 1 Remit, 2 Grow, 3 Bank,
/// 4 Merchant). Internally this widget reorders them so Home renders in
/// the middle slot; callers don't need to know about that reordering.
class NavigationBarMain extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const NavigationBarMain({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  // Semantic index -> (icon, label). Order here is display order along
  // the bar, with Home (semantic 0) placed in the middle.
  static const List<int> _visualOrder = [1, 2, 0, 3, 4];
  static const double _cornerRadius = 30;

  static const Map<int, (IconData, String)> _tabs = {
    0: (Icons.home_rounded, "Home"),
    1: (Icons.compare_arrows, "Remit"),
    2: (Icons.trending_up, "Grow"),
    3: (Icons.account_balance, "Bank"),
    4: (Icons.settings, "Settings"),
  };

  @override
  Widget build(BuildContext context) {
    final currentVisualIndex = _visualOrder.indexOf(selectedIndex);

    return Material(
      color: AppTheme.gray50,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
        child: ClipRRect(
          // Rounded on all four corners — this bar floats with padding on
          // every side (it never touches a screen edge), so leaving the top
          // corners square looked like a flat-topped mistake against the
          // rounded bottom.
          borderRadius: BorderRadius.circular(_cornerRadius),
          child: CurvedNavigationBarPro(
            currentIndex: currentVisualIndex,
            onTap: (visualIndex) => onItemSelected(_visualOrder[visualIndex]),
            backgroundColor: AppTheme.primaryPink.withAlpha(230),
            activeColor: AppTheme.primaryWhite,
            inactiveColor: AppTheme.primaryWhite,
            fabColor: AppTheme.primaryWhite,
            barHeight: 65,
            fabRadius: 20,
            fabGap: 6,
            fabSink: 14,
            notchShoulderRadius: 20,
            cornerRadius: _cornerRadius,
            showLabel: true,
            inactiveIconSize: 22,
            shadowColor: AppColors.textBlack.withAlpha(30),
            elevation: 12,
            items: List.generate(_visualOrder.length, (visualIndex) {
              final semanticIndex = _visualOrder[visualIndex];
              final (icon, label) = _tabs[semanticIndex]!;

              return CurvedNavigationItemPro(
                inactiveIcon: icon,
                // Only the active tab carries a label — it renders
                // centered on the navy bar surface below the notch,
                // never inside the curve/bubble itself.
                // label: isActive ? label : "",
                label: label,
                activeWidget: _ActiveTabContent(icon: icon),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// Icon shown inside the bubble sitting in the bar's small curve — a
/// compact navy chip nested in the white bubble. No label is ever drawn
/// here; labels are rendered by the bar itself on the flat navy surface.
class _ActiveTabContent extends StatelessWidget {
  final IconData icon;

  const _ActiveTabContent({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.secondaryNavy,
        shape: BoxShape.circle,
      ),

      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Icon(icon, color: AppTheme.primaryWhite, size: 22),
      ),
    );
  }
}
