import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

class SearchResultTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool dimmed;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        onTap: onTap,
        child: Opacity(
          opacity: dimmed ? 0.55 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingLg),
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingSm,
              horizontal: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.secondaryNavy.withValues(
                    alpha: 0.1,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 30,
                    color: AppTheme.secondaryNavy,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.labelLarge,
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
