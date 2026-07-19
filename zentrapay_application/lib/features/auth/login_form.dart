import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/features/auth/auth_text_field.dart';
import 'package:zentrapay_application/main.dart';

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

  void loginNow() async {
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

    // Prepare payload data
    Map<String, dynamic> form = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "phone_number": contact.trim(),
    };

    // Turn on the loading indicator
    setState(() {
      isLoading = true;
    });

    try {
      // Perform API request (this automatically executes Privy internal auth now)
      final res = await loginUser(form);

      // Check backend response success flag
      if (!res?['success']) {
        return ZentraNotifier.error(
          "Failed",
          res?['message'] ?? "Unknown error occurred",
        );
      }

      // Handle successful authentication
      ZentraNotifier.success("Success", res?["message"]);

      final token = res?['token'];

      await SecureStorageService.saveToken(token);

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

        Navigator.pushNamed(context, '/home', arguments: res?["user"]);
      });
    } catch (e) {
      // Catch any network, parsing, or unexpected runtime errors to prevent permanent loading loops
      if (!mounted) return;

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
        Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.primary,
          ),
          child: Column(
            spacing: 20,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                runAlignment: WrapAlignment.center,

                children: [
                  Text("Login using:", style: AppStyles.text),
                  SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        useEmail
                            ? _emailController.text = ""
                            : _contactController.text = "";
                        useEmail = !useEmail;
                      });
                    },
                    child: Text(
                      useEmail ? "Contact Number" : "Email",
                      style: AppStyles.text.copyWith(color: AppColors.main),
                    ),
                  ),
                ],
              ),
              useEmail
                  ? AuthTextField(
                      label: "Email",
                      isPassword: false,
                      controller: _emailController,
                      isLoading: isLoading,
                    )
                  : IntlPhoneField(
                      enabled: !isLoading,
                      controller: _contactController,
                      decoration: InputDecoration(
                        counterText: '',
                        labelText: "Contact No.",
                        filled: true,
                        fillColor: AppColors.lightGrey.withAlpha(50),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
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
            ],
          ),
        ),
        InkWell(
          onTap: isLoading ? null : loginNow,
          child: Container(
            width: maxWidth,
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Center(
                child: Text(
                  "Login",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),

        Text(
          "Don't have account yet?",
          style: TextStyle(color: AppColors.primary),
        ),
        GestureDetector(
          onTap: isLoading
              ? null
              : () => Navigator.pushNamed(context, '/register'),
          child: Text(
            "Create",
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
