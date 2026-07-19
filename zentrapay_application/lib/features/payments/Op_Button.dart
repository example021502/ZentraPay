import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class Op_Button extends StatelessWidget {
  const Op_Button({
    super.key,
    required this.label,
    required this.icn,
    required this.isActive,
    required this.onSelect,
  });

  final String label;
  final IconData icn;
  final bool isActive;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSelect();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isActive ? AppColors.main : Colors.grey.withAlpha(5),
          borderRadius: BorderRadius.circular(200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 5,
          children: [
            Icon(
              icn,
              size: 25,
              color: isActive
                  ? AppColors.primary
                  : AppColors.textBlack.withAlpha(80),
            ),
            Text(
              label,
              style: AppStyles.header.copyWith(
                fontWeight: FontWeight.normal,
                fontSize: 14,
                color: isActive
                    ? AppColors.primary
                    : AppColors.textBlack.withAlpha(80),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
