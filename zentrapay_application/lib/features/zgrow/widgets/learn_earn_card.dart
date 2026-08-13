import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/main.dart';

class LearnEarnCard extends StatelessWidget {
  const LearnEarnCard({
    super.key,
    required this.content,
    required this.completing,
    required this.onComplete,
  });

  final LiteracyContent content;
  final bool completing;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: const Color(0xFF1A0059),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.video_library_outlined,
                color: Colors.white,
                size: 28,
              ),
              Text(
                "${content.durationMinutes} mins",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          Text(
            content.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (content.completed)
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                SizedBox(width: 4),
                Text(
                  "Completed",
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              height: 32,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: completing ? null : onComplete,
                child: completing
                    ? const SizedBox(
                        height: 14,
                        width: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        "Complete (+${content.pointsReward})",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
