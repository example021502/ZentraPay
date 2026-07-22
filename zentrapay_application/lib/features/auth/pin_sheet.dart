import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/features/auth/custom_keypad.dart';
import 'package:zentrapay_application/features/auth/pin_verify_sheet.dart';

class PinSheet extends StatefulWidget {
  const PinSheet({super.key});
  @override
  State<PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<PinSheet> {
  String pin = "";
  void _onPress(String digit) {
    if (pin.length < 5) setState(() => pin += digit);
  }

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
            "Set Your 5-digit PIN",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "You will use this PIN to authorize transactions.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 25),
          _buildPinDots(),
          const SizedBox(height: 30),
          CustomKeypad(
            onDigitPress: _onPress,
            onDelete: () => setState(
              () =>
                  pin = pin.isNotEmpty ? pin.substring(0, pin.length - 1) : "",
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: pin.length == 5
                ? () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const PinVerifySheet(),
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "Continue",
              style: TextStyle(color: Colors.white),
            ),
          ),
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
}
