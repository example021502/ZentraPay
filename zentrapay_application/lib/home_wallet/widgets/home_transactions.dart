import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class HomeTransactions extends StatelessWidget {
  const HomeTransactions({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final titleFontSize = isTablet ? 20.0 : 16.0;
    final itemFontSize = isTablet ? 16.0 : 14.0;
    final subtitleFontSize = isTablet ? 14.0 : 12.0;
    final iconSize = isTablet ? 24.0 : 20.0;

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Activities",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to full transaction history
                },
                child: Text(
                  "View All",
                  style: TextStyle(
                    color: AppColors.main,
                    fontSize: isTablet ? 16.0 : 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _item(
            context,
            "Send to John Willis",
            "Today, 09:20",
            "-GHS 140.00",
            Icons.person_outline,
            "transfer",
            itemFontSize: itemFontSize,
            subtitleFontSize: subtitleFontSize,
            iconSize: iconSize,
          ),
          _item(
            context,
            "Received from Lucky",
            "Today, 09:20",
            "+GHS 140.00",
            Icons.person_outline,
            "receive",
            itemFontSize: itemFontSize,
            subtitleFontSize: subtitleFontSize,
            iconSize: iconSize,
          ),
          _item(
            context,
            "Send to John Willis",
            "Today, 09:20",
            "-GHS 140.00",
            Icons.flash_on_outlined,
            "transfer",
            itemFontSize: itemFontSize,
            subtitleFontSize: subtitleFontSize,
            iconSize: iconSize,
          ),
          _item(
            context,
            "Paid goods to O.K Market",
            "Today, 09:20",
            "-GHS 140.00",
            Icons.shopping_cart_outlined,
            "payment",
            itemFontSize: itemFontSize,
            subtitleFontSize: subtitleFontSize,
            iconSize: iconSize,
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context,
    String title,
    String time,
    String amount,
    IconData icon,
    String type, {
    double itemFontSize = 14,
    double subtitleFontSize = 12,
    double iconSize = 20,
  }) => GestureDetector(
    onTap: () {
      _showTransactionDetails(context, title, time, amount, type);
    },
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.grey[100],
        child: Icon(icon, size: iconSize, color: Colors.black87),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: itemFontSize),
      ),
      subtitle: Text(
        time,
        style: TextStyle(fontSize: subtitleFontSize, color: Colors.grey),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: itemFontSize,
          color: amount.startsWith("+") ? AppColors.green : AppColors.main,
        ),
      ),
    ),
  );

  void _showTransactionDetails(
    BuildContext context,
    String title,
    String time,
    String amount,
    String type,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              time,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              amount,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: amount.startsWith("+")
                    ? AppColors.green
                    : AppColors.main,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem("Type", type),
                _buildDetailItem("Status", "Completed"),
                _buildDetailItem("Reference", "TXN123456"),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.main,
                  foregroundColor: AppColors.primary,
                ),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
