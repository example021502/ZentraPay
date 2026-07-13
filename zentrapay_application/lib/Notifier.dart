import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:zentrapay_application/main.dart';

class ZentraNotifier {
  static void success(String title, String message) {
    toastification.show(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      alignment: Alignment.topLeft,
      dragToClose: true,
      showIcon: true,
      icon: Icon(Icons.check_circle_sharp, size: 30, color: AppColors.green),
      foregroundColor: AppColors.secondary,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      // Matches banking app themes
      title: Text(
        title,
        style: AppStyles.header.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      description: Text(
        message,
        style: AppStyles.text.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textBlack,
        ),
      ),

      // autoCloseDuration: const Duration(seconds: 3),
      primaryColor: AppColors.primary,
      // You can link this to AppColors.success
      borderRadius: BorderRadius.circular(20),
    );
  }

  static void error(String title, String message) {
    toastification.show(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      alignment: Alignment.topLeft,
      showIcon: true,
      dragToClose: true,
      icon: Icon(Icons.cancel_outlined, size: 30, color: AppColors.main),
      foregroundColor: AppColors.secondary,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      // Matches banking app themes
      title: Text(
        title,
        style: AppStyles.header.copyWith(color: AppColors.main, fontSize: 16),
      ),
      description: Text(
        message,
        style: AppStyles.text.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textBlack,
        ),
      ),
      // autoCloseDuration: const Duration(seconds: 3),
      primaryColor: AppColors.primary,
      // You can link this to AppColors.success
      borderRadius: BorderRadius.circular(20),
    );
  }

  static void warning(String title, String message) {
    toastification.show(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      alignment: Alignment.topLeft,
      showIcon: true,
      dragToClose: true,
      icon: Icon(Icons.warning, size: 30, color: AppColors.orange),
      foregroundColor: AppColors.secondary,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      // Matches banking app themes
      title: Text(
        title,
        style: AppStyles.header.copyWith(color: AppColors.main, fontSize: 16),
      ),
      description: Text(
        message,
        style: AppStyles.text.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textBlack,
        ),
      ),
      // autoCloseDuration: const Duration(seconds: 3),
      primaryColor: AppColors.primary,
      // You can link this to AppColors.success
      borderRadius: BorderRadius.circular(20),
    );
  }
}
