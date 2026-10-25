import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';

class LearnEarnCard extends StatelessWidget {
  const LearnEarnCard({super.key, required this.content, this.width = 190});

  final Tutorial content;

  /// Inline cards are a fixed 190px wide; the full-list screen stretches
  /// each card across the row instead.
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
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
              Icon(
                Icons.video_library_outlined,
                color: AppTheme.textBlack,
                size: 28,
              ),
              Text(
                "${content.durationSeconds} s",
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
        ],
      ),
    );
  }
}
