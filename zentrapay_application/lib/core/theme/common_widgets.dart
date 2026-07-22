import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'app_theme.dart';

/// ============================================================
/// REUSABLE WIDGETS FOR ZENTRAPAY APPLICATION
/// All feature screens should use these widgets for consistency.
/// ============================================================

/// Standard feature screen header with colored background
class FeatureScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final IconData? icon;
  final bool showBackButton;
  final Widget? trailing;

  const FeatureScreenHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.backgroundColor = AppColors.main,
    this.icon,
    this.showBackButton = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = AppTheme.isTablet(context);
    final horizontalPadding = AppTheme.responsivePadding(context);
    final titleFontSize = isTablet ? 28.0 : 24.0;
    final subtitleFontSize = isTablet ? 16.0 : 14.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppTheme.spacingLg,
      ),
      color: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBackButton)
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (icon != null) Icon(icon, color: Colors.amber, size: 30),
                if (trailing != null) trailing!,
              ],
            ),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white70,
                fontSize: subtitleFontSize,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Standard feature screen body with white background and rounded top corners
class FeatureScreenBody extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const FeatureScreenBody({
    super.key,
    required this.children,
    this.spacing = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final isTablet = AppTheme.isTablet(context);
    final maxWidth = AppTheme.responsiveMaxWidth(context);
    final horizontalPadding = AppTheme.responsivePadding(context);
    final bottomPadding = AppTheme.responsiveBottomPadding(context);

    return Center(
      child: Container(
        width: maxWidth,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppTheme.spacingLg,
              ),
              child: Column(children: children),
            ),
            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }
}

/// Standard action item card for feature screens
class ActionItemCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? backgroundColor;

  const ActionItemCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.main).withAlpha(25),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.main, size: 24),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.headlineSmall),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    subtitle,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.lightGrey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// Quick action button (circular icon with label)
class QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const QuickActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final actionColor = color ?? AppColors.main;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: actionColor.withAlpha(25),
            child: Icon(icon, color: actionColor, size: 22),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

/// Info card with icon, title, and description
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          border: Border.all(color: AppTheme.dividerColor),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.main, size: 24),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.headlineSmall),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    description,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppColors.lightGrey,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// AI Insight card
class AIInsightCard extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;

  const AIInsightCard({super.key, required this.message, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 20,
              color: AppTheme.warningOrange,
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Section title widget
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTheme.headlineLarge),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Standard search bar
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
        prefixIcon: const Icon(Icons.search, size: 20),
        hintText: hintText,
        border: InputBorder.none,
        filled: true,
        fillColor: AppColors.lightGrey.withAlpha(40),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.main, width: 1),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.lightGrey, width: 1),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
      ),
    );
  }
}

/// Coming soon snackbar helper
void showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature - Coming Soon!'),
      backgroundColor: AppColors.main,
    ),
  );
}
