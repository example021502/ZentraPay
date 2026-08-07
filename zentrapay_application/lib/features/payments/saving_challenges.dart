import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

class SavingChallenges extends StatelessWidget {
  const SavingChallenges({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Active Saving Challenges", style: AppStyles.header),
            IconButton(
              onPressed: () {
                ZentraNotifier.success("New Challenge", "Not yet implemented");
              },
              icon: const Icon(
                Icons.add_circle,
                color: AppTheme.secondaryNavy,
                size: 40,
              ),
            ),
          ],
        ),
        _buildChallengeCard(
          "Challenge 1",
          "The 30-Day Emergency Cushion",
          0.76,
          "Saved: \$450.00 / Target: \$595.00",
          "50 pts bonus",
          "active",
        ),
        _buildChallengeCard(
          "Challenge 2",
          "Local Currency Inflation Shield",
          0.0,
          "Lock \$50 in Gold for 60 Days",
          "100 pts bonus",
          "inactive",
        ),
      ],
    );
  }

  Widget _buildChallengeCard(
    String title,
    String sub,
    double progress,
    String detail,
    String reward,
    String isActive,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Text(
              sub,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              minHeight: 5,
              borderRadius: BorderRadius.circular(200),
              value: progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryPink),
            ),
            const SizedBox(height: 5),
            Wrap(
              spacing: 20,
              children: [
                Text(detail, style: const TextStyle(fontSize: 11)),
                Text(
                  "Reward: $reward",
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryPink,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            isActive.toLowerCase() != "active"
                ? Row(
                    children: [
                      InkWell(
                        onTap: () {
                          ZentraNotifier.success(
                            "Accept Challenge",
                            "Not yet implemented",
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.only(left: 10, right: 10),

                          decoration: BoxDecoration(
                            color: AppTheme.successGreen,
                            borderRadius: BorderRadius.circular(200),
                          ),
                          child: Text(
                            "Accept",
                            style: TextStyle(
                              color: AppTheme.primaryWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          ZentraNotifier.success(
                            "Ignore Challenge",
                            "Not yet implemented",
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.only(left: 10, right: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryPink,
                            borderRadius: BorderRadius.circular(200),
                          ),
                          child: Text(
                            "Ignore",
                            style: TextStyle(
                              color: AppTheme.primaryWhite,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Text(
                    "Active",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                      color: AppTheme.successGreen,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
