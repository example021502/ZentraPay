import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';

/// Shows a confirmation dialog to the user.
/// Returns [true] if the user clicks "Confirm", [false] if they click "Cancel".
Future<bool> showCloseConfirmationDialog(BuildContext context) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierDismissible: false, // Prevents closing by tapping outside
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: AppColors.primary,
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Cleaner look for dialogs
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content tightly
            children: [
              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(200),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightGrey.withAlpha(50),
                        offset: const Offset(0, 0),
                        blurRadius: 2.0,
                      ),
                    ],
                  ),
                  child: InkWell(
                    // Swapped GestureDetector for InkWell for better touch feedback
                    borderRadius: BorderRadius.circular(200),
                    onTap: () => Navigator.of(context).pop(false),
                    // Passes false back
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        "Cancel",
                        textAlign: TextAlign.center,
                        style: AppStyles.text.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16), // Replaced spacing from Wrap
              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await SecureStorageService.deleteToken();
                    if (!context.mounted) return;
                    Navigator.of(context).pop(true); // Passes true back
                  },
                  child: Text("Confirm", style: AppStyles.text),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  // If the dialog is dismissed somehow without popping a value, default to false
  return result ?? false;
}
