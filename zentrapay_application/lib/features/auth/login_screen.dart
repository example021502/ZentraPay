// Comment: Fully corrected LoginScreen code anchored to the bottom with safe scrolling behavior

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
      // Comment: LayoutBuilder ensures full available height is utilized
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: ConstrainedBox(
              // Comment: Ensure the scroll view takes at least the full height of the screen
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.end,
                    // Comment: Aligns children to the bottom
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Comment: Spacer pushes content to the bottom when there is extra vertical space
                      const Spacer(),

                      // Comment: Image asset placed above the login card
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: Image.asset("images/loginPage.png"),
                      ),

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
                          child: Column(
                            children: [
                              LoginForm(),
                              SizedBox(height: AppTheme.spacingMd),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
