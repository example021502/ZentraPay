import 'package:flutter/foundation.dart';

/// Bottom-navigation tab indices, in the same order `ResponsiveNavigation`
/// builds its `_pages` and `NavigationBarMain` builds its `_tabs`:
/// 0 Home, 1 Remit, 2 Grow, 3 Bank, 4 Settings.
///
/// Declared here (rather than inline as `0`/`1`/…) so a child screen asking to
/// jump to Home/Grow/ZBank reads as intent instead of a magic number.
///
/// IMPORTANT: these indices MUST stay in sync with the two lists above — the
/// enum's ordinal is the array index, so a mismatch silently switches the
/// wrong tab.
///
/// The stored value is named [tabIndex] rather than `index` because every Dart
/// enum already has `index` from `Enum`, and shadowing it is a compile error.
enum AppTab {
  home(0),
  zremit(1),
  grow(2),
  zbank(3),
  settings(4);

  const AppTab(this.tabIndex);

  final int tabIndex;
}

/// Lets a screen that is *not* the navigation shell ask for a tab change —
/// e.g. ZBank's "Home" quick action, or ZGrow's "Z-Invest" tile.
///
/// `ResponsiveNavigation` listens to this and mirrors [current] into its
/// `_selectedIndex`, so the navigation bar highlights the new tab too. Same
/// load-once singleton `ChangeNotifier` pattern the data repositories use.
class TabSwitchNotifier extends ChangeNotifier {
  TabSwitchNotifier._();
  static final TabSwitchNotifier instance = TabSwitchNotifier._();

  AppTab _current = AppTab.home;
  AppTab get current => _current;

  /// Ask the navigation shell to switch tabs.
  ///
  /// A no-op when the requested tab is already active — without this guard a
  /// screen calling `select` on every rebuild would re-notify forever.
  void select(AppTab tab) {
    if (_current == tab) return;
    _current = tab;
    notifyListeners();
  }
}
