import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

class AiCouch extends StatelessWidget {
  const AiCouch({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("AI Couch", style: AppStyles.header),
          const SizedBox(height: 10),
          _bubble(
            "Hi Desire! You successfully avoided weekend splurges. You have \$15 left.",
            false,
          ),
          const SizedBox(height: 15),
          _bubble("How can I effectively manage my financial wellbeing?", true),
          const SizedBox(height: 30),
          _input(),
        ],
      ),
    );
  }

  Widget _bubble(String text, bool isUser) => Align(
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isUser ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    ),
  );

  Widget _input() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(200),
    ),
    child: const Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: "Ask your couch anything",
              border: InputBorder.none,
              hintStyle: TextStyle(fontSize: 12),
            ),
          ),
        ),
        Icon(Icons.send, color: AppTheme.secondaryNavy, size: 20),
      ],
    ),
  );
}
