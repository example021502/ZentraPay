import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Rounded surface that groups the rows of one Settings section — the same
/// card treatment the Home sections use, so Settings reads as part of the app.
class SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const SettingsCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, indent: 56, color: AppTheme.dividerColor),
          ],
        ],
      ),
    );
  }
}

/// Round icon chip used at the start of every Settings row.
class SettingsIconChip extends StatelessWidget {
  final IconData icon;
  final Color? color;

  const SettingsIconChip(this.icon, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppTheme.brand;
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: tint.withAlpha(AppTheme.isDark ? 60 : 28),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: tint),
    );
  }
}

/// A Settings row with an on/off switch. [onChanged] gets no value: the screen
/// owns the flag and flips it (optimistically) itself.
class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final Future<void> Function() onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SettingsIconChip(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.labelLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.gray500,
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (_) => onChanged(),
              thumbColor: WidgetStateProperty.all(AppTheme.primaryWhite),
              trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              inactiveTrackColor: AppTheme.primaryPink,
              activeTrackColor: AppTheme.secondaryNavy,
            ),
          ],
        ),
      ),
    );
  }
}

/// A Settings row that opens something.
class SettingsNavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color? color;
  final VoidCallback onTap;

  const SettingsNavTile({
    super.key,
    required this.icon,
    required this.title,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SettingsIconChip(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTheme.labelLarge.copyWith(
                  color: color ?? AppTheme.textBlack,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: AppTheme.textBlack),
          ],
        ),
      ),
    );
  }
}
