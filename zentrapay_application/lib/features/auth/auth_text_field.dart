import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final bool isPassword;
  final TextEditingController controller;
  final bool isLoading;

  const AuthTextField({
    super.key,
    required this.isLoading,
    required this.label,
    required this.isPassword,
    required this.controller,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  // 1. Declare a mutable boolean to control visibility state locally
  late bool _isObscured;
  late String _label;

  @override
  void initState() {
    // 2. FIX: Corrected lifecycle super call syntax
    super.initState();

    // Initialize our mutable visibility state based on the incoming configuration parameters
    _isObscured = widget.isPassword;
    _label = widget.label;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: !widget.isLoading,
      controller: widget.controller,
      obscureText: _isObscured,
      style: TextStyle(color: AppColors.textBlack, fontSize: 14),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: AppColors.primary,
        label: Text(
          _label,
          style: TextStyle(
            color: AppColors.textBlack.withAlpha(153),
            fontSize: 13,
          ),
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
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.secondary.withAlpha(77),
            width: 1.5,
          ),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.secondary.withAlpha(153),
                  size: 20,
                ),
              )
            : null,
      ),
    );
  }
}
