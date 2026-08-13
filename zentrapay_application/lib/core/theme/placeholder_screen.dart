import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

/// Generic "not built yet" destination — used wherever a menu/tile links to
/// a section that doesn't have a dedicated screen yet. Pushed directly with
/// a title (`Navigator.push(context, MaterialPageRoute(builder: (_) =>
/// PlaceholderScreen(title: "Emergency Fund")))`) rather than needing a
/// bespoke screen file per stub — keeps every stub honest about being a
/// stub instead of silently no-op'ing or showing a toast.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      appBar: AppBar(
        backgroundColor: AppColors.main,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.primary, fontSize: 18),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 56,
                color: AppColors.textBlack.withAlpha(90),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle ?? "This section is coming soon.",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textBlack.withAlpha(150),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
