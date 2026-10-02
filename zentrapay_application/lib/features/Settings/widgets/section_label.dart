import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Small, muted header that opens every section on the Settings screen
/// (GENERAL, SECURITY, FEEDBACK, DANGER ZONE).
///
/// Lives in its own file rather than in `settings.dart` so `ListSection` and
/// `SecuritySection` share one copy of the styling instead of each rebuilding
/// the same label.
class SectionLabel extends StatelessWidget {
  final String title;

  const SectionLabel(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Tightened vertical padding to eliminate bloated gaps
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(
        title,
        style: AppTheme.bodyMedium.copyWith(
          color: AppTheme.textBlack.withAlpha(80),
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}
