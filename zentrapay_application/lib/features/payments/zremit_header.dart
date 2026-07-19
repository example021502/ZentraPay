import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class ZRemitHeader extends StatelessWidget {
  final String title;
  final String AmountSend = "GHS 1000";
  final String AmountReceived = "USD 11.49";
  final String rate = "1 USD = 87.03 GHS";
  final bool showBack;

  const ZRemitHeader({super.key, required this.title, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final horizontalPadding = isTablet ? 40.0 : 15.0;
    final titleFontSize = isTablet ? 32.0 : 26.0;
    final subtitleFontSize = isTablet ? 16.0 : 14.0;
    final contentFontSize = isTablet ? 18.0 : 16.0;
    final rateFontSize = isTablet ? 16.0 : 12.0;

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: AppColors.primary,
        // image: DecorationImage(
        //   image: AssetImage('images/remittance.png'),
        //   fit: BoxFit.cover,
        //   opacity: 0.50,
        // ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 5,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.main,
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Instant, Secure and affordable",
                style: TextStyle(
                  color: AppColors.main,
                  fontSize: subtitleFontSize,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              spacing: 10,
              children: [
                Text(
                  "You Send $AmountSend",
                  style: TextStyle(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.w700,
                    fontSize: contentFontSize,
                  ),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Exchange Rate: $rate",
                        style: TextStyle(
                          color: AppColors.textBlack,
                          fontWeight: FontWeight.bold,
                          fontSize: rateFontSize,
                        ),
                      ),
                      Text(
                        "Updated: just now",
                        style: TextStyle(
                          color: AppColors.textBlack,
                          fontSize: rateFontSize,
                        ),
                      ),
                    ],
                  ),
                ),

                Text(
                  "They Receive $AmountReceived",
                  style: TextStyle(
                    color: AppColors.textBlack,
                    fontWeight: FontWeight.w700,
                    fontSize: contentFontSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
