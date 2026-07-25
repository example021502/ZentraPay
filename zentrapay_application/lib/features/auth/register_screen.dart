import 'package:flutter/material.dart';
import 'package:intl_phone_field/countries.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/features/auth/SetPinDialog.dart';
import 'package:zentrapay_application/features/auth/api_auth_services.dart';
import 'package:zentrapay_application/features/auth/auth_text_field.dart';
import 'package:zentrapay_application/main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _full_nameController = TextEditingController();
  bool _isPhoneValid = false;

  Map<String, dynamic> contactForm = {"phone_number": "", "country": ""};

  bool isLoading = false;

  void register() async {
    if (_full_nameController.text.trim() == "" ||
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

    bool isValidEmail(String email) {
      final RegExp emailRegExp = RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      );
      return emailRegExp.hasMatch(email);
    }

    if (!isValidEmail(_emailController.text.trim())) {
      return ZentraNotifier.error("Invalid value", "Email is invalid");
    }

    String? PIN = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => SetPinDialog(pinLength: 4),
    );

    final Map<String, dynamic> registrationForm = {
      "full_name": _full_nameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "phone_number": contactForm['phone_number']!,
      "country": contactForm['country']!,
      "pin": PIN,
    };

    setState(() {
      isLoading = true;
    });
    final token = await SecureStorageService.getToken();
    print("TOKEN:: $token");

    try {
      final res = await registerUser(registrationForm);
      print("THE RES:: ${res}");
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
      final zentag = userData?['zentag'];

      await SecureStorageService.saveToken(token);

      //================================================
      // TO BE IMPLEMENTED LATER
      //================================================

      // final Result<PrivyUser> registrationResult = await privy.customAuth
      //     .loginWithCustomAccessToken();
      // print("REGISTRATION RESULT:: $registrationResult");
      // switch (registrationResult) {
      //   case Success(value: final user):
      //     debugPrint(
      //       "Privy auto-initialized after registration! User DID: ${user.id}",
      //     );
      //     if (user.embeddedEthereumWallets.isEmpty) {
      //       final newEthereumWallet = await user.createEthereumWallet();
      //       newEthereumWallet.fold(
      //         onSuccess: (wallet) async {
      //           final newWalletData = {
      //             "user_id": userData?['userId'],
      //             "wallet_address": userData?['userId'],
      //             "user_id": userData?['userId'],
      //           };
      //           final result = await createNewCryptoWallet(newWalletData);
      //         },
      //         onFailure: (error) {
      //           print("ERROR:: $error");
      //         },
      //       );
      //     }
      //     break;
      //
      //   case Failure(error: final err):
      //     print("Privy auto-auth after registration failed: ${err.message}");
      //     break;
      // }
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

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushNamed(
          context,
          '/home',
          arguments: {
            'token': token,
            'email': email,
            'fullName': fullName,
            'zentag': zentag,
          },
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

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 470;
    final maxWidth = isTablet ? 400.0 : MediaQuery.of(context).size.width;
    final horizontalPadding = isTablet ? 40.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.main,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.main,
              AppColors.main.withAlpha(133),
              AppColors.main.withAlpha(144),
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Elegant logo
                      Image.network(
                        'https://i.ibb.co/tjHXt0D/home-page-image.jpg',
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Create Account",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 25 : 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),

                      // Welcome text
                      Text(
                        "Let's get you started!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 14,
                          color: AppColors.primary.withAlpha(204),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 30),
                      // Elegant card container for form
                      Container(
                        width: maxWidth,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(242),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withAlpha(51),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 30 : 25),
                          child: Column(
                            spacing: 16,
                            children: [
                              AuthTextField(
                                label: "Full Name",
                                isPassword: false,
                                controller: _full_nameController,
                                isLoading: isLoading,
                              ),
                              AuthTextField(
                                label: "Email Address",
                                isPassword: false,
                                controller: _emailController,
                                isLoading: isLoading,
                              ),

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
                                      color: AppColors.secondary.withAlpha(77),
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
                                  print(
                                    "PHONE NUMBER:: ${phone.completeNumber}",
                                  );
                                  setState(() {
                                    contactForm['phone_number'] =
                                        phone.completeNumber;
                                    _isPhoneValid = phone.isValidNumber();

                                    // Look up country safely and update the correct 'country' key
                                    final country = countries.firstWhere(
                                      (element) =>
                                          element.code == phone.countryISOCode,
                                    );
                                    contactForm['country'] = country.name;
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
                      ),
                      const SizedBox(height: 24),
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
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textBlack.withAlpha(30),
                                  blurRadius: 10,
                                  offset: const Offset(0, 0),
                                ),
                              ],
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
                              color: AppColors.primary.withAlpha(204),
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    Navigator.pushNamed(context, '/login');
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
            );
          },
        ),
      ),
    );
  }
}
