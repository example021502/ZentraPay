import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

class OnboardingPageWidget extends StatelessWidget {
  final String title;
  final String description;
  final String imageLink;

  const OnboardingPageWidget({
    super.key,
    required this.title,
    required this.description,
    required this.imageLink,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 4,
            child: Container(
              // margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: AssetImage(imageLink),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.whiteDisplayMedium,
          ),
          const SizedBox(height: AppTheme.spacingLg),

          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTheme.whiteBody.copyWith(fontSize: 18),
          ),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }
}
