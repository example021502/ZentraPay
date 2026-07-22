import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class ZInvestHeader extends StatelessWidget {
  const ZInvestHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      color: AppColors.main,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Spacer(),
              const Icon(Icons.rocket_launch, color: Colors.amber, size: 30),
            ],
          ),
          const Text(
            "Investments & Financial\nWellness",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Investment",
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "GHS 3, 728.28",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "+35.6%",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "All time",
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() => Row(
    children: [
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.download, size: 18),
          label: const Text("Deposit"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.main,
          ),
        ),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.upload, size: 18),
          label: const Text("Withdraw"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    ],
  );
}
