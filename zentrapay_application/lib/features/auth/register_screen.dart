// Comment: Full updated RegisterScreen code with fixed Checkbox state management and comments included

import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/AppSetPinSheet.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/features/auth/api_auth_services.dart';
import 'package:zentrapay_application/features/auth/auth_text_field.dart';
import 'package:zentrapay_application/main.dart';

import '../../core/repositories/providers_repository.dart';
import '../../core/repositories/transactions_repository.dart';
import '../../core/repositories/wallets_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _isPhoneValid = false;
  String pin = "";
  bool termsConsent = false;
  Map<String, dynamic> contactForm = {"phone_number": "", "country_code": ""};

  bool isLoading = false;

  void register() async {
    if (_firstNameController.text.trim() == "" ||
        _lastNameController.text.trim() == "" ||
        _emailController.text.trim() == "" ||
        contactForm['phone_number'] == "") {
      return ZentraNotifier.error(
        "Missing Value(s)",
        "All fields are required",
      );
    }

    if (!_isPhoneValid) {
      return ZentraNotifier.error("Invalid value", "Invalid Phone number");
    }

    // Comment: Validate termsConsent and conditions agreement before proceeding
    if (!termsConsent) {
      return ZentraNotifier.error(
        "Terms Required",
        "Please accept the Terms of Service and Privacy Policy",
      );
    }

    bool isValidEmail(String email) {
      final RegExp emailRegExp = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      return emailRegExp.hasMatch(email);
    }

    if (!isValidEmail(_emailController.text.trim())) {
      return ZentraNotifier.error("Invalid value", "Email is invalid");
    }

    if (pin == "") {
      String? pinValue = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) => const AppSetPinSheet(pinLength: 4),
      );
      setState(() {
        pin = pinValue!;
      });
    }

    final Map<String, dynamic> registrationForm = {
      "firstName": _firstNameController.text.trim(),
      "lastName": _lastNameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "phoneNumber": contactForm['phone_number']!,
      "countryCode": contactForm['country_code']!,
      "pin": pin,
      "termsConsent": termsConsent,
      // "privacyPolicyId": null,
      // "termsOfUseId": null,
    };

    setState(() {
      isLoading = true;
    });

    try {
      final res = await registerUser(registrationForm);
      print("THE RES:: $res");
      if (!res?["success"]) {
        return ZentraNotifier.error(
          "Failed",
          res?["message"] ?? "Unknown Error!",
        );
      }
      ZentraNotifier.success("Success", res?["message"]);

      // Extract user data from nested 'data' field
      final userData = res?['data'];
      final token = userData?['token'];
      final email = userData?['email'];
      final fullName = userData?['fullName'];
      print("TOKEN IS:: $token");

      await SecureStorageService.saveToken(token);
      WalletsRepository.instance.ensureLoaded();
      BillProvidersRepository.instance.ensureLoaded();
      ServiceProvidersRepository.instance.ensureLoaded();
      TransactionsRepository.instance.ensureLoaded();
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          '/home',
          arguments: {'token': token, 'email': email, 'fullName': fullName},
        );
      });
    } catch (e) {
      if (!mounted) return;
      ZentraNotifier.error("Error", "Registration Failed!, try again.");
      debugPrint("ERROR:: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Comment: Updated method signature to accept bool? to match Checkbox onChanged callback
  void onCheckTermsAndConditions(bool? value) {
    setState(() {
      termsConsent = value ?? false;
    });
  }

  @override
  void dispose() {
    // Comment: Disposing all controllers to prevent memory leaks
    _passwordController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 470;
    final maxWidth = isTablet ? 400.0 : MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.main,
      resizeToAvoidBottomInset: true,
      // Comment: LayoutBuilder dynamically measures screen constraints
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              // Comment: Ensures the content takes at least the full viewport height
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Comment: Spacer leaves space at the top above the white container
                    const SizedBox(height: 40),
                    Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      decoration: AppTheme.cardDecoration.copyWith(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.0,
                          vertical: 30.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Create your",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isTablet ? 35 : 30,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textBlack,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spacingSm),
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
                                  ],
                                ),
                                Text(
                                  "Account",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isTablet ? 35 : 30,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textBlack,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                const SizedBox(height: AppTheme.spacingMd),
                                AuthTextField(
                                  label: "First Name",
                                  isPassword: false,
                                  controller: _firstNameController,
                                  isLoading: isLoading,
                                ),
                                const SizedBox(height: 16),
                                AuthTextField(
                                  label: "Last Name",
                                  isPassword: false,
                                  controller: _lastNameController,
                                  isLoading: isLoading,
                                ),
                                const SizedBox(height: 16),
                                AuthTextField(
                                  label: "Email Address",
                                  isPassword: false,
                                  controller: _emailController,
                                  isLoading: isLoading,
                                ),
                                const SizedBox(height: 16),
                                // Phone field (contact number)
                                IntlPhoneField(
                                  enabled: !isLoading,
                                  dropdownDecoration: const BoxDecoration(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    labelText: "Contact Number",
                                    filled: true,
                                    fillColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: AppColors.textBlack.withAlpha(153),
                                      fontSize: 13,
                                    ),
                                    hintStyle: TextStyle(
                                      color: AppColors.textBlack.withAlpha(102),
                                      fontSize: 13,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColors.secondary.withAlpha(
                                          77,
                                        ),
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
                                        color: AppColors.secondary.withAlpha(
                                          77,
                                        ),
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                  initialCountryCode: 'GH',
                                  onChanged: (phone) {
                                    print(
                                      "PHONE NUMBER:: ${phone.completeNumber}",
                                    );
                                    setState(() {
                                      contactForm['phone_number'] =
                                          phone.completeNumber;
                                      _isPhoneValid = phone.isValidNumber();
                                      contactForm['country_code'] =
                                          phone.countryISOCode;
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                AuthTextField(
                                  label: "Password",
                                  isPassword: true,
                                  controller: _passwordController,
                                  isLoading: isLoading,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Row(
                              children: [
                                // Comment: Properly bound Checkbox value to termsConsent state and onChanged handler
                                Checkbox(
                                  value: termsConsent,
                                  onChanged: onCheckTermsAndConditions,
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      spacing: 15,
                                      children: [
                                        Text(
                                          "I agree to the",
                                          style: AppTheme.bodySmall,
                                        ),
                                        Text(
                                          "Terms of Service",
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.primaryPink,
                                          ),
                                        ),
                                        Text("and", style: AppTheme.bodySmall),
                                      ],
                                    ),
                                    Text(
                                      "Privacy Policy",
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppColors.main,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            // Elegant register button with gradient
                            Material(
                              color: Colors.transparent,
                              child: GestureDetector(
                                onTap: !isLoading ? register : null,
                                child: Container(
                                  width: maxWidth,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: AppTheme.cardShadow,
                                  ),
                                  child: Center(
                                    child: isLoading
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    AppColors.primary,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            "Create Account",
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
                            const SizedBox(height: 24),
                            // Footer links
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textBlack.withAlpha(204),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: isLoading
                                      ? null
                                      : () {
                                          Navigator.pushNamed(
                                            context,
                                            '/login',
                                          );
                                        },
                                  child: Text(
                                    "Sign In",
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
                        ),
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
