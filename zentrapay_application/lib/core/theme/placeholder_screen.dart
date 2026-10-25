import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';

/// Generic "not built yet" destination - used wherever a menu/tile links to
/// a section that doesn't have a dedicated screen yet. Pushed directly with
/// a title (`Navigator.push(context, MaterialPageRoute(builder: (_) =>
/// PlaceholderScreen(title: "Something")))`) rather than needing a bespoke
/// screen file per stub - keeps every stub honest about being a stub instead
/// of silently no-op'ing or showing a toast. Uses the shared titled
/// [SectionHeader] like every other section, not an app bar.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          SectionHeader(
            title: title,
            subtitle: "Coming soon",
            icon: Icons.construction_rounded,
            showBack: true,
            sheetColor: AppTheme.gray50,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.construction_outlined,
                      size: 56,
                      color: AppTheme.textBlack,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: AppTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle ?? "This section is coming soon.",
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.gray500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
