import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/auth/custom_keypad.dart';

class PinVerifySheet extends StatefulWidget {
  const PinVerifySheet({super.key});
  @override
  State<PinVerifySheet> createState() => _PinVerifySheetState();
}

class _PinVerifySheetState extends State<PinVerifySheet> {
  String pin = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Verify PIN",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text("Enter your PIN again.", textAlign: TextAlign.center),
          const SizedBox(height: 25),
          _buildPinDots(),
          const SizedBox(height: 30),
          CustomKeypad(
            onDigitPress: (v) {
              if (pin.length < 5) setState(() => pin += v);
            },
            onDelete: () => setState(
              () =>
                  pin = pin.isNotEmpty ? pin.substring(0, pin.length - 1) : "",
            ),
          ),
          const SizedBox(height: 30),
          _buildButtons(context),
        ],
      ),
    );
  }

  Widget _buildPinDots() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      5,
      (i) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: i < pin.length
              ? AppColors.secondary
              : AppColors.main.withAlpha(76),
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
          child: const Text("Back", style: TextStyle(color: AppColors.main)),
        ),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: ElevatedButton(
          onPressed: pin.length == 5
              ? () {
                  ZentraNotifier.success(
                    "PIN set successfully!",
                    "Now continue and set your biometrics details.",
                  );
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            minimumSize: const Size(0, 55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: const Text("Verify", style: TextStyle(color: Colors.white)),
        ),
      ),
    ],
  );
}
