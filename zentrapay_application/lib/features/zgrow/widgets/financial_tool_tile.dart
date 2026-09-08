import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/main.dart';

class FinancialToolTile extends StatelessWidget {
  const FinancialToolTile({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
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
                Column(
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
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
              ],
            ),
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
