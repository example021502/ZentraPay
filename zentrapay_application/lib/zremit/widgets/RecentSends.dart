import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

final List<Map<String, String>> recentRecipients = [
  {
    "id": "1",
    "name": "Leanne Graham",
    "contact": "+44 345 2453 524",
    "country": "U.K",
  },
  {
    "id": "2",
    "name": "Ervin Howell",
    "contact": "+263 242 4525 245",
    "country": "Zimbabwe",
  },
  {
    "id": "3",
    "name": "James Harwin",
    "contact": "+263 242 4525 245",
    "country": "Zimbabwe",
  },
];

class RecentSends extends StatelessWidget {
  const RecentSends({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 5,
      children: [
        Text("Send Again", style: AppStyles.header),
        const SizedBox(height: 10),
        // Spacing between header and list
        // 1. Wrap in a SizedBox to give the horizontal list a strict height boundary
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentRecipients.length,
            itemBuilder: (context, index) {
              final recipient = recentRecipients[index];

              // 2. Use a fixed-width container layout instead of a ListTile
              return Padding(
                padding: EdgeInsets.only(right: 20),
                child: Column(
                  children: [
                    const CircleAvatar(radius: 25, child: Icon(Icons.person)),
                    const SizedBox(height: 4),
                    // 3. Properly wrap strings inside Text widgets
                    Text(
                      recipient['name']?.split(' ').join('\n') ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
