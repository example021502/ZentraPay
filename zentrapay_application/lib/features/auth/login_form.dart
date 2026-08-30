import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/features/auth/auth_text_field.dart';
import 'package:zentrapay_application/main.dart';

import '../../core/repositories/providers_repository.dart';
import '../../core/repositories/transactions_repository.dart';
import '../../core/repositories/wallets_repository.dart';
import '../../core/theme/app_theme.dart';
import 'api_auth_services.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool useEmail = true;
  String contact = "";
  bool isLoading = false;

  late final bool isTablet = MediaQuery.of(context).size.width == 470;
  late final double maxWidth = isTablet
      ? 400
      : MediaQuery.of(context).size.width;

  void loginNowTemp() async {
    Navigator.pushNamed(
      context,
      '/home',
      arguments: {
        'zentag': 'Testing',
        'email': "Testing@gmail.com",
        'fullName': "Testing testing",
      },
    );
  }

  void loginNow() {
    Navigator.pushNamed(
      context,
      '/home',
      arguments: {'email': "email@gmail.com", 'fullName': "bypass name"},
    );
  }

  void loginNowD() async {
    debugPrint('LOGIN init');
    // Validate credentials before initiating the login process
    if (_emailController.text == "") {
      if (contact == "") {
        return ZentraNotifier.error(
          "Missing Credential",
          "Email or Phone number missing!",
        );
      }
    }
    if (_passwordController.text == "") {
      return ZentraNotifier.error("Missing Credential", "Password missing");
    }

    // Validate email format if an email is provided
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (_emailController.text != "" &&
        !emailPattern.hasMatch(_emailController.text.trim())) {
      return ZentraNotifier.error("Error", "Invalid Email");
    }

    // Prepare payload data — field names must match LoginRequestDTO
    // ({email, phoneNumber, password}) on the Spring Boot backend.
    Map<String, dynamic> form = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "phoneNumber": contact.trim(),
    };

    // Turn on the loading indicator
    setState(() {
      isLoading = true;
    });

    try {
      // Perform API request (this automatically executes Privy internal auth now)
      final res = await loginUser(form);
      print("RES:: $res");
      // Check backend response success flag
      if (!res?['success'] || res?['data'] == null) {
        return ZentraNotifier.error(
          "Failed",
          res?['message'] ?? "Unknown error occurred",
        );
      }
      print("PASSED--=");

      // Handle successful authentication
      ZentraNotifier.success(
        "Success",
        res?["message"]! ?? "Login Successful.",
      );

      // Extract user data from nested 'data' field
      final userData = res?['data'];
      final token = userData?['token'];
      final email = userData?['email'];
      final fullName = userData?['fullName'];
      final zentag = userData?['zentag'];

      await SecureStorageService.saveToken(token);
      WalletsRepository.instance.ensureLoaded();
      BillProvidersRepository.instance.ensureLoaded();
      ServiceProvidersRepository.instance.ensureLoaded();
      TransactionsRepository.instance.ensureLoaded();
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        // ========================================================
        // TO IMPLEMENT CRYPTO LATER
        // ========================================================

        // final privyUser = await privy.getUser();
        // if (privyUser != null && privyUser.embeddedEthereumWallets.isNotEmpty) {
        //   debugPrint("Redirecting to dashboard. User Web3 ID: ${privyUser.id}");
        //   debugPrint(
        //     "Active Smart Wallet Address: ${privyUser.embeddedEthereumWallets.first.address}",
        //   );
        // } else {
        //   debugPrint(
        //     "Warning: App login cleared but Privy session initialization is pending or failed.",
        //   );
        // }

        // Pass user data as arguments
        Navigator.pushNamed(
          context,
          '/home',
          arguments: {'zentag': zentag, 'email': email, 'fullName': fullName},
        );
      });
    } catch (e) {
      // Catch any network, parsing, or unexpected runtime errors to prevent permanent loading loops
      if (!mounted) return;
      debugPrint('LOGIN EXCEPTION: $e');
      ZentraNotifier.error(
        "Error",
        "An unexpected error occurred: ${e.toString()}",
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Clean up all individual text field controllers
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      children: [
        Column(
          children: [
            Text(
              "Login to your",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 35 : 30,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
                letterSpacing: 0.5,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Zentrapay",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 35 : 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.main,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  "Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isTablet ? 35 : 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Elegant toggle for login method
        Container(
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(90),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            runAlignment: WrapAlignment.center,
            children: [
              Text(
                "Login using:",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    useEmail
                        ? _emailController.text = ""
                        : _contactController.text = "";
                    useEmail = !useEmail;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    useEmail ? "Contact Number" : "Email",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        useEmail
            ? AuthTextField(
                label: "Email Address",
                isPassword: false,
                controller: _emailController,
                isLoading: isLoading,
              )
            : IntlPhoneField(
                enabled: !isLoading,
                controller: _contactController,
                decoration: InputDecoration(
                  counterText: '',
                  labelText: "Contact Number",
                  filled: true,
                  fillColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: AppColors.textBlack.withAlpha(60),
                    fontSize: 13,
                  ),
                  hintStyle: TextStyle(
                    color: AppColors.textBlack.withAlpha(40),
                    fontSize: 13,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.secondary.withAlpha(80),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.secondary,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.secondary.withAlpha(30),
                      width: 1.5,
                    ),
                  ),
                ),
                initialCountryCode: 'GH',
                onChanged: (phone) {
                  setState(() {
                    contact = phone.completeNumber;
                  });
                },
              ),

        AuthTextField(
          label: "Password",
          isPassword: true,
          controller: _passwordController,
          isLoading: isLoading,
        ),

        // Elegant login button with gradient
        Material(
          child: GestureDetector(
            onTap: isLoading ? null : loginNow,
            child: Container(
              width: maxWidth,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        "Log In",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 5,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(fontSize: 12, color: AppColors.textBlack),
            ),
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () => Navigator.pushNamed(context, '/register'),
              child: Text(
                "Sign Up",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
