import 'package:flutter/widgets.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';

/// Owns the app's light / dark mode.
///
/// AppTheme's colour tokens are plain getters that read [AppTheme.isDark], so
/// flipping the flag is not enough on its own: widgets that did not depend on
/// the Material `Theme` would keep the colours they were last built with.
/// [setDark] therefore flips the flag, tells the root `MaterialApp` to rebuild
/// with the matching `ThemeData`, and marks every element dirty so the whole
/// tree is rebuilt in the next frame — the app re-colours instantly, with no
/// navigation or screen state lost.
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  bool get isDark => AppTheme.isDark;

  /// Restores the mode saved on this device. Call once before `runApp`.
  Future<void> restore() async {
    AppTheme.isDark = await SecureStorageService.readDarkMode();
  }

  /// Switches mode immediately and remembers it on this device.
  ///
  /// Persisting to the backend is the caller's job (see
  /// `AppSettingsRepository.setDarkMode`), because only the caller knows how
  /// to revert when that fails.
  void setDark(bool dark) {
    if (AppTheme.isDark == dark) return;
    AppTheme.isDark = dark;
    SecureStorageService.saveDarkMode(dark);
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
