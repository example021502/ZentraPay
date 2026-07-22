import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class RecentActivities extends StatelessWidget {
  const RecentActivities({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Recent Activities", style: AppStyles.header),
          const SizedBox(height: 10),
          _buildActivity("Send to John Willis", "Today, 09:20", "-GHS 140.00"),
          _buildActivity("Received from Lucky", "Today, 09:20", "+GHS 140.00"),
          _buildActivity("Send to John Willis", "Today, 09:20", "-GHS 140.00"),
          _buildActivity(
            "Paid goods to O.K Market",
            "Today, 09:20",
            "-GHS 140.00",
          ),
        ],
      ),
    );
  }

  Widget _buildActivity(String title, String time, String amount) {
    final isNegative = amount.startsWith("-");
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[100],
        child: const Icon(Icons.person_outline, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(time, style: const TextStyle(fontSize: 12)),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isNegative ? AppColors.main : AppColors.green,
        ),
      ),
    );
  }
}
