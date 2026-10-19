// Import required Flutter material package
import 'package:flutter/material.dart';
// Import the pretty_qr_code package for QR rendering
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

class PrettyQrWidget extends StatelessWidget {
  // Pass the extracted string variable into the widget
  final String qrData;

  const PrettyQrWidget({
    super.key,
    required this.qrData, // Constructor requires the variable
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: PrettyQrView.data(
          // Pass the variable directly here
          data: qrData,
          decoration: const PrettyQrDecoration(
            image: PrettyQrDecorationImage(
              image: AssetImage('images/logo.png'),
            ),
            shape: PrettyQrSmoothSymbol(color: AppTheme.secondaryNavy),
          ),
        ),
      ),
    );
  }
}
