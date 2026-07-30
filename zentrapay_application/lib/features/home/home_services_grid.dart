// Always provide comments in the code.
import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class HomeServicesGrid extends StatefulWidget {
  const HomeServicesGrid({
    super.key,
    required this.services,
    required this.bills,
  });

  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> bills;

  @override
  State<HomeServicesGrid> createState() => _HomeServicesGridState();
}

class _HomeServicesGridState extends State<HomeServicesGrid> {
  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
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
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                widget.bills.isEmpty
                    ? Center(
                        child: Text(
                          "No Bill Providers",
                          style: TextStyle(
                            color: AppColors.lightGrey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.bills.length,
                          itemBuilder: (BuildContext context, int i) {
                            final item = widget.bills[i];
                            return _buildItem(
                              item['logoUrl'],
                              item['billerName'] ?? "N/A",
                              () => _showComingSoon(
                                context,
                                item['billerName'] ?? "N/A",
                              ),
                              iconSize: iconSize,
                              fontSize: fontSize,
                              isTablet: isTablet,
                            );
                          },
                        ),
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

          const SizedBox(height: 30),
          Text("Financial Services", style: AppStyles.header),
          const SizedBox(height: 20),
          SizedBox(
            width: MediaQuery.of(context).size.width,
            height: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                widget.services.isEmpty
                    ? Center(
                        child: Text(
                          "No Service Providers",
                          style: TextStyle(
                            color: AppColors.lightGrey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.services.length,
                          itemBuilder: (BuildContext context, int i) {
                            final item = widget.services[i];
                            return _buildItem(
                              item['logoUrl'],
                              item['providerName'] ?? "N/A",
                              () => _showComingSoon(
                                context,
                                item['providerName'],
                              ),
                              iconSize: iconSize,
                              fontSize: fontSize,
                              isTablet: isTablet,
                            );
                          },
                        ),
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

  Widget _buildItem(
    String imgUrl,
    String label,
    VoidCallback onTap, {
    double iconSize = 24,
    double fontSize = 12,
    required bool isTablet,
  }) {
    final itemWidth =
        (MediaQuery.of(context).size.width - (isTablet ? 40 : 20) * 2 - 30) / 4;

    return SizedBox(
      width: itemWidth,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            imgUrl != ""
                ? Image.network(imgUrl)
                : Icon(Icons.grid_3x3, color: Colors.black54, size: iconSize),

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
