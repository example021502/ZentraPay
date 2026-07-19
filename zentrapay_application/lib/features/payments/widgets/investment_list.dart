import 'package:flutter/material.dart';

class InvestmentList extends StatelessWidget {
  const InvestmentList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Investments",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 15),
          _item("ZGrowth Fund", "+6.4%", "GHS 140.00"),
          _item("ZBalanced Fund", "-6.4%", "GHS 1, 230.00"),
          _item("ZMoney Market", "+6.4%", "GHS 2, 040.00"),
          const SizedBox(height: 20),
          _buildExploreButton(),
        ],
      ),
    );
  }

  Widget _item(String title, String percent, String amount) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const CircleAvatar(
      backgroundColor: Colors.white,
      child: Icon(Icons.show_chart, size: 18, color: Colors.grey),
    ),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
    subtitle: Text(
      percent,
      style: TextStyle(
        color: percent.startsWith("+") ? Colors.green : Colors.red,
        fontSize: 12,
      ),
    ),
    trailing: Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _buildExploreButton() => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 120),
    child: ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF210163),
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text(
        "Explore Market",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
