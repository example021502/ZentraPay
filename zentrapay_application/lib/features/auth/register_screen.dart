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
        contactForm['phone_number'] == "" ||
        contactForm["country"] == "") {
      return ZentraNotifier.error(
        "Missing Value(s)",
        "All fields are required",
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
    try {
      final res = await registerUser(registrationForm);
      if (!res?["success"]) {
        return ZentraNotifier.error(
          "Failed",
          res?["message"] ?? "Unknown Error!",
        );
      }
      ZentraNotifier.success("Success", res?["message"]);

      final token = res?['token'];
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
      //             "user_id": res.data['user_id'],
      //             "wallet_address": res.data['user_id'],
      //             "user_id": res.data['user_id'],
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
        Navigator.pushNamed(context, '/home', arguments: res?["user"]);
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
    final maxWidth = isTablet ? 300.0 : MediaQuery.of(context).size.width;
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final imageHeight = isTablet ? 200.0 : 150.0;
    final titleFontSize = isTablet ? 28.0 : 20.0;
    final containerPadding = isTablet ? 24.0 : 20.0;

    return Scaffold(
      backgroundColor: AppColors.main,
      // Keeps your background color intact
      resizeToAvoidBottomInset: true,
      // Tells scaffold to shrink when keyboard appears
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
                    // Centering now works perfectly because the parent fills the viewport height
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image(
                        image: const AssetImage('images/home_page_image.jpg'),
                        width: maxWidth,
                        height: imageHeight,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Create Account",
                        textAlign: TextAlign.center,
                        style: AppStyles.header.copyWith(
                          color: AppColors.primary,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Form fields container ====================
                      SizedBox(
                        width: maxWidth,
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(
                            vertical: containerPadding,
                            horizontal: containerPadding,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            spacing: 15,
                            children: [
                              if (isLoading) CircularProgressIndicator(),

                              AuthTextField(
                                label: "Full name",
                                isPassword: false,
                                controller: _full_nameController,
                                isLoading: isLoading,
                              ),
                              AuthTextField(
                                label: "Email",
                                isPassword: false,
                                controller: _emailController,
                                isLoading: isLoading,
                              ),

                              // Phone field (contact number)
                              IntlPhoneField(
                                enabled: !isLoading,
                                dropdownDecoration: const BoxDecoration(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(10),
                                  ),
                                ),
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
                                    contactForm['contact'] =
                                        phone.completeNumber;
                                    setState(() {
                                      _isPhoneValid = phone.isValidNumber();
                                    });

                                    // FIX: Look up country safely and update the correct 'country' key
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
                      const SizedBox(height: 20),

                      // Submit button container ====================
                      SizedBox(
                        width: maxWidth,
                        child: Container(
                          height: 55,
                          width: double.infinity,
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: GestureDetector(
                            onTap: !isLoading && _isPhoneValid
                                ? register
                                : null,
                            child: Text(
                              "Create",
                              style: AppStyles.header.copyWith(
                                color: AppColors.primary,
                                fontSize: isTablet ? 18.0 : 15.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Footer links ====================
                      Column(
                        spacing: 5,
                        children: [
                          Text(
                            "Already have an account?",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: isTablet ? 16.0 : 14.0,
                            ),
                          ),
                          GestureDetector(
                            onTap: isLoading
                                ? null
                                : () {
                                    Navigator.pushNamed(context, '/login');
                                  },
                            child: Text(
                              "Login",
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: isTablet ? 16.0 : 14.0,
                              ),
                            ),
                          ),
                        ],
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
