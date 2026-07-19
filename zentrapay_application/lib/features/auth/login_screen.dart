import 'package:flutter/material.dart';
import 'package:zentrapay_application/features/auth/login_form.dart';
import 'package:zentrapay_application/main.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 470;
    final maxWidth = isTablet ? 300.0 : MediaQuery.of(context).size.width;
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final imageHeight = isTablet ? 200.0 : 100.0;
    final titleFontSize = isTablet ? 20.0 : 18.0;

    return Scaffold(
      backgroundColor: AppColors.main,
      // Keeps your background color intact
      resizeToAvoidBottomInset: true,
      // Tells the scaffold to resize when the keyboard pops up
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              // Forces the contents to be at least the full height of the viewport
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    // Vertically centers the elements within the viewport space
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 20,
                    children: [
                      Image(
                        image: const AssetImage('images/home_page_image.jpg'),
                        width: maxWidth,
                        height: imageHeight,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      Text(
                        "Sign In",
                        textAlign: TextAlign.center,
                        style: AppStyles.header.copyWith(
                          color: AppColors.primary,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      SizedBox(width: maxWidth, child: const LoginForm()),
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
