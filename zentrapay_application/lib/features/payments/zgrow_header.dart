import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class ZGrowHeader extends StatelessWidget {
  const ZGrowHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final titleFontSize = isTablet ? 24.0 : 20.0;
    final subtitleFontSize = isTablet ? 16.0 : 14.0;
    final circleSize = isTablet ? 160.0 : 140.0;
    final strokeWidth = isTablet ? 18.0 : 15.0;
    final scoreFontSize = isTablet ? 36.0 : 30.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 30,
      ),
      color: AppColors.main,
      child: Column(
        children: [
          Text(
            "Monthly Financial Health Score:",
            style: TextStyle(
              color: Colors.white,
              fontSize: titleFontSize,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          _buildCircularScore(
            circleSize: circleSize,
            strokeWidth: strokeWidth,
            scoreFontSize: scoreFontSize,
          ),
          const SizedBox(height: 15),
          Text(
            "Your next Milestone unlocks in 3 days",
            style: TextStyle(color: Colors.white70, fontSize: subtitleFontSize),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularScore({
    double circleSize = 140,
    double strokeWidth = 15,
    double scoreFontSize = 30,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: circleSize,
          height: circleSize,
          child: CircularProgressIndicator(
            value: 0.867,
            strokeWidth: strokeWidth,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
          ),
        ),
        Text(
          "86.7%",
          style: TextStyle(
            color: Colors.green,
            fontSize: scoreFontSize,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
