// Comment: Fully corrected LoginScreen code with proper child property and safe scrolling behavior

import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/auth/login_form.dart';
import 'package:zentrapay_application/main.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Comment: Determine if the device width corresponds to a tablet layout
    final isTablet = MediaQuery.of(context).size.width >= 470;
    final maxWidth = isTablet ? 400.0 : MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.main,
      resizeToAvoidBottomInset: true,
      // Comment: LayoutBuilder retrieves available screen height dynamically
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Comment: Image asset placed in upper flexible area
                    Image.asset("images/loginPage.png"),
                    // Comment: Bottom container holding the login form
                    Container(
                      width: maxWidth,
                      decoration: AppTheme.cardDecoration.copyWith(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 15.0,
                          vertical: 30.0,
                        ),
                        // Comment: Fixed syntax by properly assigning child property
                        child: LoginForm(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
