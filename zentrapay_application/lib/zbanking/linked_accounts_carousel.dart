import 'package:flutter/material.dart';
import 'package:zentrapay_application/Notifier.dart';
import 'package:zentrapay_application/main.dart';

class LinkedAccountsCarousel extends StatefulWidget {
  const LinkedAccountsCarousel({super.key});
  @override
  State<LinkedAccountsCarousel> createState() => _LinkedAccountsCarouselState();
}

class _LinkedAccountsCarouselState extends State<LinkedAccountsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool visible = false;
  final List<Map<String, String>> _accounts = [
    {"bank": "Ecobank Ghana PLC", "percent": "14.5%", "value": "GHS 34,435.43"},
    {
      "bank": "HSBC Holdings plc, UK",
      "percent": "14.5%",
      "value": "USD 22,433.23",
    },
    {
      "bank": "Mitsubishi UFJ (MUFG), Japan",
      "percent": "12.5%",
      "value": "YEN 34,345.35",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _accounts.length,
            itemBuilder: (_, i) => i < _accounts.length
                ? _buildAccountCard(_accounts[i])
                : ElevatedButton(
                    onPressed: () {
                      ZentraNotifier.success(
                        "Go back to start",
                        "Not Implemented yet!",
                      );
                    },
                    child: Icon(
                      Icons.first_page,
                      color: AppColors.main,
                      size: 20,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        _buildIndicators(),
      ],
    );
  }

  Widget _buildAccountCard(Map<String, String> data) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      color: AppColors.main,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Your banking Profile",
                  style: TextStyle(color: Colors.white70),
                ),
                const Text(
                  "June 06, 2026",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(200),
              ),
              child: Text(
                "${data['percent']} \u2191",
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data['bank']!,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    visible ? data['value'] ?? '' : "----.--",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        visible = !visible;
                      });
                    },
                    child: Icon(
                      visible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicators() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      _accounts.length,
      (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _currentPage == i ? AppColors.main : Colors.grey,
        ),
      ),
    ),
  );
}
