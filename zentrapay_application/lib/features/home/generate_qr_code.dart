// Import required Flutter material package
import 'package:flutter/material.dart';
// Import the pretty_qr_code package for QR rendering
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

class PrettyQrWidget extends StatelessWidget {
  // Pass the extracted string variable into the widget
  final String qrData;

  /// Rendered square size in logical pixels.
  final double size;

  const PrettyQrWidget({
    super.key,
    required this.qrData, // Constructor requires the variable
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    // Embeddable-only widget: no Scaffold/AppBar here so it can live inside
    // sheets, dialogs and cards. Falls back to a placeholder when there is
    // nothing to encode — PrettyQrView asserts on empty data, which used to
    // crash the Receive sheet while the user profile was still loading.
    if (qrData.trim().isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(
            Icons.qr_code_2,
            size: size * 0.4,
            color: AppTheme.textBlack,
          ),
        ),
      );
    }
    // Scanners need dark modules on a light background, so the code is always
    // drawn navy on white — even in dark mode, where the surrounding card is dark.
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: PrettyQrView.data(
            // Pass the variable directly here
            data: qrData,
            errorCorrectLevel: QrErrorCorrectLevel.H,
            decoration: const PrettyQrDecoration(
              image: PrettyQrDecorationImage(
                // pubspec serves images/ + .env; images/logo.png never existed,
                // so the embedded logo silently failed. Reuse the bundled logo.
                image: AssetImage('images/logo.jpg'),
              ),
              shape: PrettyQrSmoothSymbol(color: AppTheme.secondaryNavy),
            ),
          ),
        ),
      ),
    );
  }
}
