import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/auth/pin_sheet.dart';

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
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Verify Your Account",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Enter the 6-digit code sent to\njohnywill1234@gmail.com",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        const SizedBox(height: 40),
                        _buildOtpFields(),
                        const SizedBox(height: 30),
                        const Text(
                          "Resend code in 00:30s",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.main,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Image.network(
                          'https://img.freepik.com/free-vector/otp-authentication-concept-illustration_114360-9133.jpg',
                          height: 180,
                        ),
                        const SizedBox(height: 50),
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
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            "${i + 1}",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
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
          onPressed: () {
            ZentraNotifier.success(
              "Account Verified!",
              "Now continue and set your PIN",
            );
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => const PinSheet(),
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
