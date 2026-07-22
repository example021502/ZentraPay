// Always provide comments in the code.
import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/home/api_home_wallet_services.dart';
import 'package:zentrapay_application/main.dart';

class HomeServicesGrid extends StatefulWidget {
  const HomeServicesGrid({super.key});

  @override
  State<HomeServicesGrid> createState() => _HomeServicesGridState();
}

class _HomeServicesGridState extends State<HomeServicesGrid> {
  List<Map<String, dynamic>> billProviders = [];

  void _loadBillProviders() async {
    try {
      final response = await getBillProviders();

      if (!response["success"]) {
        debugPrint("ERROR:: ${response["message"]}");
        return;
      }
      setState(() {
        billProviders = response["billProviders"];
      });
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _loadBillProviders();
  }

  // Storing raw IconData references directly to prevent type mismatches inside builders
  final List<Map<String, dynamic>> services = [
    {"name": "Loans", "icon": Icons.money},
    {"name": "Car\nInsurance", "icon": Icons.directions_car_outlined},
    {"name": "Health\nInsurance", "icon": Icons.health_and_safety},
    {"name": "ZInvest", "icon": Icons.trending_up_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery
        .of(context)
        .size
        .width >= 600;
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final iconSize = isTablet ? 32.0 : 24.0;
    final fontSize = isTablet ? 14.0 : 12.0;

    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Bills", style: AppStyles.header),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildItem(
                Icons.lightbulb_outline,
                "Electricity\nBill",
                    () => _showComingSoon(context, "Electricity Bill Payment"),
                iconSize: iconSize,
                fontSize: fontSize,
                isTablet: isTablet,
              ),
              _buildItem(
                Icons.opacity,
                "Water\nBill",
                    () => _showComingSoon(context, "Water Bill Payment"),
                iconSize: iconSize,
                fontSize: fontSize,
                isTablet: isTablet,
              ),
              _buildItem(
                Icons.phone_android,
                "Airtime &\nBundles",
                    () => _showComingSoon(context, "Airtime & Bundles"),
                iconSize: iconSize,
                fontSize: fontSize,
                isTablet: isTablet,
              ),
              _buildItem(
                Icons.wifi,
                "Wifi\nBills",
                    () => _showComingSoon(context, "WiFi Bill Payment"),
                iconSize: iconSize,
                fontSize: fontSize,
                isTablet: isTablet,
              ),
            ],
          ),
          const SizedBox(height: 30),
          Text("Financial Services", style: AppStyles.header),
          const SizedBox(height: 20),

          // Enclosed bounded layout frame designed to protect horizontal engine structures
          SizedBox(
            width: MediaQuery
                .of(context)
                .size
                .width,
            height: 80,
            child: Row(
              children: [
                // Horizontal scrolling engine wrapped inside Expanded to fix semantics errors
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: services.length,
                    itemBuilder: (BuildContext context, int i) {
                      final item = services[i];
                      return _buildItem(
                        item['icon'],
                        item['name'],
                            () => _showComingSoon(context, item['name']),
                        iconSize: iconSize,
                        fontSize: fontSize,
                        isTablet: isTablet,
                      );
                    },
                  ),
                ),

                // Subtle dividing block providing isolation for action triggers
                VerticalDivider(
                  color: Colors.grey.shade300,
                  thickness: 1,
                  indent: 10,
                  endIndent: 10,
                ),

                // Securely bound side option trigger to introduce new elements into the engine
                GestureDetector(
                  onTap: () {
                    // Action implementation triggers here
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_outlined,
                          size: 20,
                          color: AppColors.textBlack,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "New",
                          style: TextStyle(
                            color: AppColors.textBlack,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon,
      String label,
      VoidCallback onTap, {
        double iconSize = 24,
        double fontSize = 12,
        required bool isTablet,
      }) {
    final itemWidth =
        (MediaQuery
            .of(context)
            .size
            .width - (isTablet ? 40 : 20) * 2 - 30) / 4;

    return SizedBox(
      width: itemWidth,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.black54, size: iconSize),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: AppColors.main,
      ),
    );
  }
}
