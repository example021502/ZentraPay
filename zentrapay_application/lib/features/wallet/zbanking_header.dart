import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class ZBankingHeader extends StatelessWidget {
  const ZBankingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final horizontalPadding = isTablet ? 40.0 : 15.0;
    final overviewFontSize = isTablet ? 18.0 : 16.0;
    final titleFontSize = isTablet ? 28.0 : 24.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 20,
      ),
      color: AppColors.main,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ZBanking Overview",
            style: TextStyle(color: Colors.white70, fontSize: overviewFontSize),
          ),
          const SizedBox(height: 5),
          Text(
            "Next-gen banking.\nEffortless living",
            style: TextStyle(
              color: Colors.white,
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          _buildOverviewCard(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final cardPadding = isTablet ? 24.0 : 20.0;
    final cardFontSize = isTablet ? 18.0 : 16.0;
    final balanceFontSize = isTablet ? 24.0 : 20.0;

    return Card(
      color: AppColors.main,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ZBanking",
                  style: AppStyles.header.copyWith(
                    color: AppColors.primary,
                    fontSize: cardFontSize,
                  ),
                ),
                Text(
                  "June 06, 2026",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: cardFontSize * 0.9,
                  ),
                ),
              ],
            ),
            SizedBox(height: cardPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ZBankingBalance(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: cardPadding * 0.6,
                    vertical: cardPadding * 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.all(Radius.circular(200)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: AppColors.green,
                        size: cardFontSize,
                      ),
                      Text(
                        "14.5%",
                        style: TextStyle(
                          color: AppColors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: cardFontSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ZBankingBalance extends StatefulWidget {
  const ZBankingBalance({super.key});

  @override
  State<ZBankingBalance> createState() => _ZBankingBalanceState();
}

class _ZBankingBalanceState extends State<ZBankingBalance> {
  final value = "GHS 3,345,456.00";
  bool visible = false;

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final labelFontSize = isTablet ? 16.0 : 14.0;
    final valueFontSize = isTablet ? 28.0 : 20.0;
    final iconSize = isTablet ? 28.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Balance",
          style: TextStyle(color: Colors.white70, fontSize: labelFontSize),
        ),
        Row(
          children: [
            Text(
              visible ? value : "----.--",
              style: TextStyle(
                color: Colors.white,
                fontSize: valueFontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: isTablet ? 24.0 : 20.0),
            InkWell(
              onTap: () {
                setState(() {
                  visible = !visible;
                });
              },
              child: Icon(
                Icons.visibility_outlined,
                color: Colors.white70,
                size: iconSize,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
