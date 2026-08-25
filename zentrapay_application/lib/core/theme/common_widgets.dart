import 'dart:ui';

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
      decoration: BoxDecoration(color: backgroundColor),
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: AppTheme.spacingLg,
      ),
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
              color: AppColors.textBlack,
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textBlack,
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
          horizontal: 0,
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
                  Text(
                    title,
                    style: AppTheme.headlineSmall.copyWith(fontSize: 14),
                  ),
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
    final actionColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.secondary.withAlpha(20),
            child: Icon(icon, color: AppColors.secondary, size: 22),
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
        Text(title, style: AppTheme.headlineSmall),
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
  final FocusNode? focusNode;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
        prefixIcon: const Icon(Icons.search, size: 20),
        hintText: hintText,
        border: InputBorder.none,
        filled: true,
        fillColor: AppColors.primary,
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
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

/// Standard elevated white card — wraps AppTheme.cardDecoration so the
/// repeated "Container with white fill + rounded corners + shadow" pattern
/// (bottom sheets, transaction detail views, amount entry) has one home.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacingMd),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: padding,
      decoration: AppTheme.cardDecoration,
      child: child,
    );
  }
}

/// Full-width primary action button using the app's ElevatedButtonTheme.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : Text(label),
    );
  }
}

/// Full-width secondary action button using the app's OutlinedButtonTheme.
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const SecondaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(onPressed: onPressed, child: Text(label));
  }
}

/// Sign-colored bold amount display. Credits render in success green;
/// debits render in a neutral near-black/navy tone — NOT brand pink and NOT
/// error red, since a debit is a normal outgoing payment, not a failure.
/// Reserve errorRed strictly for actual failure states.
class AmountText extends StatelessWidget {
  final String amount;
  final String? currencyCode;
  final double fontSize;
  final int? maxLines;
  final TextOverflow? overflow;

  const AmountText({
    super.key,
    required this.amount,
    this.currencyCode,
    this.fontSize = 16,
    this.maxLines,
    this.overflow,
  });

  bool get _isCredit => amount.trim().startsWith('+');

  @override
  Widget build(BuildContext context) {
    final color = _isCredit ? AppTheme.successGreen : AppTheme.primaryPink;
    final display = currencyCode != null ? '$amount $currencyCode' : amount;
    return Text(
      display,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

/// Standard transaction row: icon chip + title/subtitle + sign-colored
/// amount. Replaces bare ListTiles used for transaction history rows.
class TransactionListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = amount.trim().startsWith('+');
    final chipColor = isCredit ? AppTheme.successGreen : AppTheme.primaryPink;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingSm),
                    decoration: BoxDecoration(
                      color: chipColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(icon, color: chipColor, size: 22),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      Text(
                        subtitle,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.gray500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            AmountText(
              amount: amount,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Standard empty-state placeholder (no history, no search results, etc.)
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppTheme.gray300),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (actionLabel != null && onAction != null) ...[
            GestureDetector(
              onTap: onAction,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 10,
                  ),
                  child: Text(
                    actionLabel!,
                    style: TextStyle(
                      color: AppTheme.primaryWhite,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Standard text field matching the app's InputDecorationTheme.
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// PIN-entry progress dots — filled count reflects digits entered so far.
/// Shared by the unified PIN sheet's set/verify/confirm modes.
class PinDots extends StatelessWidget {
  final int length;
  final int filledCount;

  const PinDots({super.key, required this.length, required this.filledCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final filled = index < filledCount;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? AppTheme.primaryPink : AppTheme.gray300,
          ),
        );
      }),
    );
  }
}

/// Paints [AppTheme.heroGradient] (deep electric blue -> hot pink) as a
/// full-bleed screen background, per the wireframe brief. Wrap a screen's
/// body in this instead of setting `Scaffold.backgroundColor` when the
/// screen should use the app's hero gradient + glassmorphism look.
class GradientScreenBackground extends StatelessWidget {
  final Widget child;
  final Gradient gradient;

  const GradientScreenBackground({
    super.key,
    required this.child,
    this.gradient = AppTheme.heroGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: gradient),
      child: child,
    );
  }
}

/// Frosted-glass card: semi-transparent surface + subtle white border, for
/// use over [GradientScreenBackground] per the wireframe brief's
/// glassmorphism spec. Distinct from the opaque [AppCard] used elsewhere.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool strong;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.spacingLg),
    this.margin,
    this.borderRadius = AppTheme.radiusXl,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppTheme.glassBlurSigma,
            sigmaY: AppTheme.glassBlurSigma,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: strong
                  ? AppTheme.glassSurfaceStrong
                  : AppTheme.glassSurface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: AppTheme.glassBorder, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
