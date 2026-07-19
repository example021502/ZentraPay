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
      // 3. FIX: Track the local state variable, not the rigid widget parameter
      obscureText: _isObscured,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        filled: true,
        fillColor: AppColors.lightGrey.withAlpha(50),
        label: Text(_label),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        // 4. FIX: Interactive interactive suffix management layout engine
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isObscured =
                        !_isObscured; // Toggles visibility representation
                  });
                },
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.grey,
                ),
              )
            : null,
      ),
    );
  }
}
