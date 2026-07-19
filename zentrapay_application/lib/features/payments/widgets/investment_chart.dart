import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class InvestmentChart extends StatelessWidget {
  const InvestmentChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabs(),
        Container(
          margin: const EdgeInsets.all(20),
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.show_chart, size: 100, color: AppColors.main),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ["D", "1W", "1M", "1Y"]
                    .map(
                      (t) => Text(
                        t,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      _tab("Stocks", true),
      _tab("Crypto", false),
      _tab("Commodities", false),
    ],
  );

  Widget _tab(String label, bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    decoration: BoxDecoration(
      color: active ? AppColors.secondary : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: active ? Colors.white : Colors.grey,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
