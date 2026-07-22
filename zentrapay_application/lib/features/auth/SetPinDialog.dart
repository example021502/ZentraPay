import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart'; // Ensure correct import for AppColors & AppStyles

class SetPinDialog extends StatefulWidget {
  final int pinLength;

  const SetPinDialog({super.key, this.pinLength = 4});

  @override
  State<SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<SetPinDialog> {
  // Global step indicator: 0 = Enter PIN, 1 = Confirm PIN
  int _currentStep = 0;

  // Controllers, focus nodes, and buffers for the initial PIN configuration step
  late List<TextEditingController> _pinControllers;
  late List<FocusNode> _pinFocusNodes;
  final List<String> _pinValues = [];

  // Separate controllers, focus nodes, and buffers for the verification step
  late List<TextEditingController> _confirmControllers;
  late List<FocusNode> _confirmFocusNodes;
  final List<String> _confirmValues = [];

  @override
  void initState() {
    super.initState();

    // Set up structures for Step 0 (Set PIN)
    _pinControllers = List.generate(
      widget.pinLength,
      (_) => TextEditingController(),
    );
    _pinFocusNodes = List.generate(widget.pinLength, (_) => FocusNode());
    _pinValues.addAll(List.generate(widget.pinLength, (_) => ""));

    // Set up structures for Step 1 (Confirm PIN)
    _confirmControllers = List.generate(
      widget.pinLength,
      (_) => TextEditingController(),
    );
    _confirmFocusNodes = List.generate(widget.pinLength, (_) => FocusNode());
    _confirmValues.addAll(List.generate(widget.pinLength, (_) => ""));
  }

  @override
  void dispose() {
    // Clean up all resources cleanly to prevent leaks
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    for (var controller in _confirmControllers) {
      controller.dispose();
    }
    for (var node in _confirmFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // Validates compliance between step 1 and step 2 inputs
  void _handlePinSubmission() {
    final firstPin = _pinValues.join();
    final secondPin = _confirmValues.join();

    if (_currentStep == 0) {
      if (firstPin.length == widget.pinLength) {
        setState(() {
          _currentStep =
              1; // Shifts current view state triggering the sliding animation
        });

        // Minor microtask delay to let the animation start before focusing the new text field safely
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            FocusScope.of(context).requestFocus(_confirmFocusNodes[0]);
          }
        });
      }
    } else {
      if (firstPin == secondPin) {
        Navigator.of(
          context,
        ).pop(firstPin); // Success: return matching PIN data payload
      } else {
        // Clear configuration mismatch gracefully
        _resetConfirmStep();
        ZentraNotifier.error("Mismatch", "PIN don't match");
      }
    }
  }

  // Wipes entries for verification retries if strings do not align match specs
  void _resetConfirmStep() {
    setState(() {
      for (int i = 0; i < widget.pinLength; i++) {
        _confirmControllers[i].clear();
        _confirmValues[i] = "";
      }
    });
    FocusScope.of(context).requestFocus(_confirmFocusNodes[0]);
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isCompleted = _currentStep == 0
        ? _pinValues.join().length == widget.pinLength
        : _confirmValues.join().length == widget.pinLength;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Align(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            width: MediaQuery.of(context).size.width * 0.90,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.lightGrey.withAlpha(50),
                  spreadRadius: 2.0,
                  blurRadius: 10.0,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withAlpha(20),
                      borderRadius: BorderRadius.circular(200),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      size: 30,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Smoothly swap Header Texts based on active steps
                  Text(
                    _currentStep == 0
                        ? "Set Payment PIN"
                        : "Confirm Payment PIN",
                    style: AppStyles.header.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentStep == 0
                        ? "Create a secure code to authorize transactions"
                        : "Re-enter your code to confirm authentication access",
                    textAlign: TextAlign.center,
                    style: AppStyles.text.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),

                  // The Animated Switcher handles horizontal layout translation swapping components
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      // Configures incoming fields to slide in from right, outgoing to pass left
                      final inAnimation = Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation);

                      final outAnimation = Tween<Offset>(
                        begin: const Offset(-1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation);

                      return SlideTransition(
                        position: child.key == ValueKey<int>(_currentStep)
                            ? inAnimation
                            : outAnimation,
                        child: child,
                      );
                    },
                    // Unique ValueKey guarantees clean system animation frames
                    child: Row(
                      key: ValueKey<int>(_currentStep),
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(widget.pinLength, (index) {
                        return SizedBox(
                          width: 54,
                          height: 54,
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (event) {
                              if (event is KeyDownEvent &&
                                  event.logicalKey ==
                                      LogicalKeyboardKey.backspace &&
                                  index > 0) {
                                final currentControllers = _currentStep == 0
                                    ? _pinControllers
                                    : _confirmControllers;
                                final currentFocusNodes = _currentStep == 0
                                    ? _pinFocusNodes
                                    : _confirmFocusNodes;

                                if (currentControllers[index].text.isEmpty) {
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(currentFocusNodes[index - 1]);
                                }
                              }
                            },
                            child: TextField(
                              controller: _currentStep == 0
                                  ? _pinControllers[index]
                                  : _confirmControllers[index],
                              focusNode: _currentStep == 0
                                  ? _pinFocusNodes[index]
                                  : _confirmFocusNodes[index],
                              autofocus: index == 0,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              obscureText: true,
                              obscuringCharacter: '●',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(1),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                counterText: "",
                                contentPadding: EdgeInsets.zero,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.lightGrey.withAlpha(100),
                                    width: 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.secondary,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (_currentStep == 0) {
                                  _pinValues[index] = value;
                                } else {
                                  _confirmValues[index] = value;
                                }

                                if (value.isNotEmpty) {
                                  final currentFocusNodes = _currentStep == 0
                                      ? _pinFocusNodes
                                      : _confirmFocusNodes;
                                  if (index < widget.pinLength - 1) {
                                    FocusScope.of(context).requestFocus(
                                      currentFocusNodes[index + 1],
                                    );
                                  } else {
                                    currentFocusNodes[index].unfocus();
                                    _handlePinSubmission();
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_currentStep != 0)
                        InkWell(
                          onTap: () {
                            // Let users slide back to step 0 to correct mistakes manually
                            setState(() {
                              _currentStep = 0;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.main.withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "Back",
                              style: AppStyles.text.copyWith(
                                color: AppColors.main,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 30),
                      InkWell(
                        onTap: isCompleted ? _handlePinSubmission : null,

                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Center(
                              child: Text(
                                _currentStep == 0 ? "Continue" : "Confirm",
                                style: AppStyles.header.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
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
      ),
    );
  }
}
