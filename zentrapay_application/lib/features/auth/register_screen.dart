import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/app_set_pin_sheet.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/core/utils/session_reset.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/features/auth/api_auth_services.dart';
import 'package:zentrapay_application/features/auth/auth_text_field.dart';
import 'package:zentrapay_application/main.dart';

import '../../features/home/repository/cache_home_data.dart';

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
  String emailError = '';
  String passwordError = '';
  String firstNameError = '';
  String lastNameError = '';
  String phoneNumberError = '';
  String consentError = '';

  bool _isPhoneValid = false;
  String pin = "";
  bool termsConsent = false;
  Map<String, dynamic> contactForm = {"phone_number": "", "country_code": ""};

  bool isLoading = false;
  bool hasFieldError = false;

  void register() async {
    if (hasFieldError) {
      setState(() {
        hasFieldError = false;
        firstNameError = '';
        lastNameError = '';
        emailError = '';
        phoneNumberError = '';
        passwordError = '';
      });
    }

    // Comment: Validate required input text fields
    if (_firstNameController.text.trim() == "" ||
        _lastNameController.text.trim() == "" ||
        _emailController.text.trim() == "" ||
        contactForm['phone_number'] == "") {
      return ZentraNotifier.error(
        "Missing Value(s)",
        "All fields are required",
      );
    }

    if (_firstNameController.text.trim() == "") {
      setState(() {
        firstNameError = "Firstname required!";
        hasFieldError = true;
      });
    }
    if (_lastNameController.text.trim() == "") {
      setState(() {
        lastNameError = "Lastname required!";
        hasFieldError = true;
      });
    }
    if (_emailController.text.trim() == "") {
      setState(() {
        emailError = "Email required!";
        hasFieldError = true;
      });
    }
    if (!_emailController.text.trim().contains("@")) {
      setState(() {
        emailError = "Invalid Email!";
        hasFieldError = true;
      });
    }
    if (_passwordController.text.trim() == "") {
      setState(() {
        passwordError = "Password required!";
        hasFieldError = true;
      });
    }
    if (_passwordController.text.trim().length < 6) {
      setState(() {
        passwordError = "password too short! Atleast 6 characters!";
        hasFieldError = true;
      });
    }
    if (contactForm['phone_number'].trim() == "") {
      setState(() {
        firstNameError = "phone number required!";
        hasFieldError = true;
      });
    }
    if (contactForm['phone_number'].trim().length < 10) {
      setState(() {
        firstNameError = "Invalid phone number!";
        hasFieldError = true;
      });
    }

    // Comment: Validate phone number format
    if (!_isPhoneValid) {
      setState(() {
        hasFieldError = true;
      });
      hasFieldError = true;
      return ZentraNotifier.error("Invalid value", "Invalid Phone number");
    }

    // Comment: Validate terms and conditions check status
    if (!termsConsent) {
      setState(() {
        hasFieldError = true;
      });
      return ZentraNotifier.error(
        "Terms Required",
        "Please accept the Terms of Service and Privacy Policy",
      );
    }

    // Comment: Regex verification helper for user email address format
    bool isValidEmail(String email) {
      final RegExp emailRegExp = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      return emailRegExp.hasMatch(email);
    }

    if (!isValidEmail(_emailController.text.trim())) {
      setState(() {
        hasFieldError = true;
      });
      return ZentraNotifier.error("Invalid value", "Email is invalid");
    }
    if (hasFieldError) return;

    // Comment: Request security PIN bottom sheet input if not already defined
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
      "phoneNumber": contactForm['phone_number']!.trim(),
      "countryCode": contactForm['country_code']!.trim(),
      "pin": pin,
      "termsConsent": termsConsent,
    };

    // Comment: Trigger loading state during async request processing
    setState(() {
      isLoading = true;
    });

    try {
      final res = await registerUser(registrationForm);
      if (!res?["success"]) {
        return ZentraNotifier.error(
          "Failed",
          res?["message"] ?? "Unknown Error!",
        );
      }
      ZentraNotifier.success("Success", res?["message"]);

      // The backend returns {token, userId, email, firstName, lastName} - the
      // same shape as login. Keep the token AND the identity, and clear what
      // the previous user left in the caches first.
      final userData = Map<String, dynamic>.from(res?['data']);
      final token = userData['token'];

      clearUserCaches();
      await SecureStorageService.saveToken(token);
      await SecureStorageService.saveSession(userData);
      WalletsRepository.instance.ensureLoaded();
      BillProvidersRepository.instance.ensureLoaded();
      ServiceProvidersRepository.instance.ensureLoaded();
      // Fire-and-forget preload: must not block post-registration navigation.
      TransactionsRepository.instance.ensureLoaded().catchError((_) {});
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: userData,
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

  // Comment: Update check mark state when box is toggled by user
  void onCheckTermsAndConditions(bool? value) {
    setState(() {
      termsConsent = value ?? false;
    });
  }

  @override
  void dispose() {
    // Comment: Dispose remaining active TextEditingControllers on unmount
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryWhite,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15.0,
                          vertical: 20.0,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: "Create your ",
                                    style: TextStyle(
                                      fontSize: isTablet ? 35 : 30,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textBlack,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "Zentrapay ",
                                    style: TextStyle(
                                      fontSize: isTablet ? 35 : 30,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.main,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: "Account",
                                    style: TextStyle(
                                      fontSize: isTablet ? 35 : 30,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textBlack,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryPink.withAlpha(10),
                                border: Border.all(
                                  color: AppTheme.primaryPink,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Note:",
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textBlack,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      "Please enter a valid name and surname, this will be used to link other external accounts for security purposes.",
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textBlack,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            AuthTextField(
                              label: "First Name",
                              isPassword: false,
                              controller: _firstNameController,
                              isLoading: isLoading,
                              errorText: firstNameError,
                            ),
                            AuthTextField(
                              label: "Last Name",
                              isPassword: false,
                              controller: _lastNameController,
                              isLoading: isLoading,
                              errorText: lastNameError,
                            ),
                            AuthTextField(
                              label: "Email Address",
                              isPassword: false,
                              controller: _emailController,
                              isLoading: isLoading,
                              errorText: emailError,
                            ),
                            IntlPhoneField(
                              enabled: !isLoading,
                              dropdownDecoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                              ),
                              decoration: InputDecoration(
                                errorText: phoneNumberError,
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
                                    color: AppColors.secondary.withAlpha(77),
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.main.withAlpha(77),
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
                                    color: AppColors.secondary.withAlpha(77),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              initialCountryCode: 'GH',
                              onChanged: (phone) {
                                setState(() {
                                  contactForm['phone_number'] =
                                      phone.completeNumber;
                                  _isPhoneValid = phone.isValidNumber();
                                  contactForm['country_code'] =
                                      phone.countryISOCode;
                                });
                              },
                            ),
                            AuthTextField(
                              label: "Password",
                              isPassword: true,
                              controller: _passwordController,
                              isLoading: isLoading,
                              errorText: passwordError,
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: termsConsent,
                                  onChanged: onCheckTermsAndConditions,
                                ),
                                const SizedBox(width: AppTheme.spacingSm),
                                // Comment: Wrapped terms text area with Expanded and RichText to prevent horizontal web overflow
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      style: AppTheme.bodySmall,
                                      children: [
                                        const TextSpan(text: "I agree to the "),
                                        TextSpan(
                                          text: "Terms of Service",
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppTheme.primaryPink,
                                          ),
                                        ),
                                        const TextSpan(text: " and "),
                                        TextSpan(
                                          text: "Privacy Policy",
                                          style: AppTheme.bodySmall.copyWith(
                                            color: AppColors.main,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingSm),
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
                            const SizedBox(height: 20),
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
