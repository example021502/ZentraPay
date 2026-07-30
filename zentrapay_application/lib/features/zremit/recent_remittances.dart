import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class RecentRemittances extends StatelessWidget {
  final List<Map<String, dynamic>> remittances;

  const RecentRemittances({super.key, required this.remittances});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Remittances",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: remittances.length,
          itemBuilder: (context, index) {
            final tx = remittances[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(tx["avatar"], color: AppColors.secondary),
                ),
                title: Text(
                  tx["recipient"],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  "${tx["corridor"]} • ${tx["date"]}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tx["amount"],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      tx["status"],
                      style: TextStyle(
                        fontSize: 12,
                        color: tx["status"] == "Completed"
                            ? AppColors.green
                            : AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
