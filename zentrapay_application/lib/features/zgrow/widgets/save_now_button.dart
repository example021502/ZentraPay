import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/payments/milestones_screen.dart';
import 'package:zentrapay_application/main.dart';

class SaveNowButton extends StatelessWidget {
  const SaveNowButton({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const MilestonesScreen())),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(30),
          borderRadius: BorderRadius.circular(200),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 15, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(200),
                  color: AppColors.primary.withAlpha(70),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.arrow_downward,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                "Save Now",
                style: AppTheme.bodyMedium.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
