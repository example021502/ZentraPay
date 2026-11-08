import 'package:flutter/widgets.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';

/// Owns the app's light / dark mode.
///
/// Dark mode belongs to the SIGNED-IN ACCOUNT, not to the device:
///  * the splash, onboarding, login, register and verify screens are always
///    light, because nobody is signed in while they are on screen (the app
///    starts light and [forceLight] runs on logout);
///  * [applyForCurrentUser] switches to the saved choice of whoever just signed
///    in (login, register, or a still-valid session found by the splash);
///  * the choice is saved under that user's id, so another account on the same
///    device never inherits it.
///
/// AppTheme's colour tokens are plain getters that read [AppTheme.isDark], so
/// flipping the flag is not enough on its own: widgets that did not depend on
/// the Material `Theme` would keep the colours they were last built with.
/// Changing the mode therefore tells the root `MaterialApp` to rebuild with
/// the matching `ThemeData`, and marks every element dirty so the whole tree
/// is rebuilt in the next frame — the app re-colours instantly, with no
/// navigation or screen state lost.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  bool get isDark => AppTheme.isDark;

  /// Loads the signed-in user's saved mode (light when nobody is signed in or
  /// nothing was saved). Call right before entering the signed-in app.
  Future<void> applyForCurrentUser() async {
    final userId = SecureStorageService.getUserId() ?? '';
    final dark = await SecureStorageService.readDarkMode(userId);
    _apply(dark);
  }

  /// Switches mode immediately and remembers it for the signed-in user.
  ///
  /// Persisting to the backend is the caller's job (see
  /// `SecuritySettingsRepository.updatePreferences`), because only the caller
  /// knows how to revert when that fails.
  void setDark(bool dark) {
    if (AppTheme.isDark == dark) return;
    final userId = SecureStorageService.getUserId() ?? '';
    // No signed-in user means this is not a user choice (e.g. a late settings
    // response arriving after logout) — never let it stick.
    if (userId.isEmpty) return;
    SecureStorageService.saveDarkMode(userId, dark);
    _apply(dark);
  }

  /// Back to light WITHOUT touching anything saved — used on logout so the
  /// login / register screens are light and the account's choice is kept.
  void forceLight() => _apply(false);

  void _apply(bool dark) {
    if (AppTheme.isDark == dark) return;
    AppTheme.isDark = dark;
    notifyListeners();
    _rebuildEverything();
  }

  void _rebuildEverything() {
    void markDirty(Element element) {
      element.markNeedsBuild();
      element.visitChildren(markDirty);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(markDirty);
  }
}
