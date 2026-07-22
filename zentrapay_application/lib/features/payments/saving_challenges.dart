import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';

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
                color: AppColors.secondary,
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
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
              valueColor: const AlwaysStoppedAnimation(AppColors.main),
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
                    color: AppColors.main,
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
                            color: AppColors.green,
                            borderRadius: BorderRadius.circular(200),
                          ),
                          child: Text(
                            "Accept",
                            style: TextStyle(
                              color: AppColors.primary,
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
                            color: AppColors.main,
                            borderRadius: BorderRadius.circular(200),
                          ),
                          child: Text(
                            "Ignore",
                            style: TextStyle(
                              color: AppColors.primary,
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
                      color: AppColors.green,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
