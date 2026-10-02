import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

// Interactive list item widget representing an individual financial tool item.
class FinancialToolTile extends StatelessWidget {
  const FinancialToolTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  // Icon displayed on the leading side of the tile
  final IconData icon;

  // Title string representing the financial tool
  final String title;

  // Description text providing brief context
  final String description;

  // Callback triggered when the tile is tapped
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                // Leading icon container with circular background tint
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(20),
                    borderRadius: BorderRadius.circular(200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(icon, color: AppColors.secondary, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
                // Expanded constrains the column to available space, preventing overflow
                Expanded(
                  child: Column(
                    // Align text left relative to the icon container
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTheme.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        style: AppTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Trailing arrow indicating navigability
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
            // Bottom divider line separating list items
            Container(
              margin: const EdgeInsets.only(top: 10),
              color: AppColors.secondary.withAlpha(20),
              width: MediaQuery.of(context).size.width,
              height: 0.5,
            ),
          ],
        ),
      ),
    );
  }
}
