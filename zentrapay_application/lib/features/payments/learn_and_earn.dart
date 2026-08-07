import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

final List<Map<String, String>> tutorials = [
  {"desc": "Compound Interest...", "duration": "3 mins"},
  {"desc": "Mastering Cash...", "duration": "4 mins"},
];

class LearnAndEarn extends StatelessWidget {
  const LearnAndEarn({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: [
        Text("Learn & Earn", style: AppStyles.header),

        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tutorials.length,
            itemBuilder: (context, index) {
              final cItem = tutorials[index];
              return _buildVideoCard(
                cItem['desc'] ?? "No description found",
                cItem['duration'] ?? "No duration found",
              );
            },
            separatorBuilder: (BuildContext context, int index) =>
                SizedBox(width: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(String title, String duration) {
    return Container(
      // clipBehavior: ,
      width: 200,

      decoration: BoxDecoration(
        color: AppTheme.secondaryNavy,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Expanded(
            flex: 3,
            child: Icon(Icons.movie, color: Colors.white, size: 60),
          ),
          const SizedBox(height: 5),
          Text(
            duration,
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border.all(color: AppTheme.secondaryNavy, width: 1.5),
            ),
            child: Text(
              title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
