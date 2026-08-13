import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/AppSetPinSheet.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';

class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.main,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.fromLTRB(30, 40, 30, 50),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radiusXxl),
                      ),
                      boxShadow: AppTheme.elevatedShadow,
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Verify Your Account",
                          style: AppTheme.displaySmall,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          "Enter the 6-digit code sent to\njohnywill1234@gmail.com",
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.gray500,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXxl),
                        _buildOtpFields(),
                        const SizedBox(height: AppTheme.spacingXl),
                        const Text(
                          "Resend code in 00:30s",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.main,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXxl),
                        // Native icon-based visual — the original relied on a
                        // freepik.com-hosted illustration, a fragile network
                        // dependency for core auth chrome.
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryNavy.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            size: 60,
                            color: AppTheme.secondaryNavy,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingXxl),
                        _buildButtons(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOtpFields() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: List.generate(
      6,
      (i) => Container(
        width: 45,
        height: 50,
        decoration: BoxDecoration(
          color: AppTheme.gray100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.gray300),
        ),
        child: Center(child: Text("${i + 1}", style: AppTheme.headlineLarge)),
      ),
    ),
  );

  Widget _buildButtons(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.main),
            minimumSize: const Size(0, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            "Back",
            style: TextStyle(color: AppColors.main, fontSize: 16),
          ),
        ),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: ElevatedButton(
          onPressed: () async {
            ZentraNotifier.success(
              "Account Verified!",
              "Now continue and set your PIN",
            );
            final pin = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              isDismissible: false,
              backgroundColor: Colors.transparent,
              builder: (context) => const AppSetPinSheet(pinLength: 4),
            );
            if (pin == null || !context.mounted) return;
            ZentraNotifier.success(
              "PIN set successfully!",
              "Now continue and set your biometrics details.",
            );
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            minimumSize: const Size(0, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text(
            "Verify",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    ],
  );
}
