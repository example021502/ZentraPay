import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class PayoutMethodSelector extends StatelessWidget {
  final String selectedOption;
  final ValueChanged<String> onOptionChanged;

  const PayoutMethodSelector({
    super.key,
    required this.selectedOption,
    required this.onOptionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => onOptionChanged('bank'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selectedOption == 'bank'
                    ? AppColors.secondary
                    : Colors.grey.shade200,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
              ),
              child: Text(
                "Bank Account",
                style: TextStyle(
                  color: selectedOption == 'bank'
                      ? AppColors.primary
                      : AppColors.textBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onOptionChanged('momo'),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selectedOption == 'momo'
                    ? AppColors.secondary
                    : Colors.grey.shade200,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(10),
                ),
              ),
              child: Text(
                "Mobile Money",
                style: TextStyle(
                  color: selectedOption == 'momo'
                      ? AppColors.primary
                      : AppColors.textBlack,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
