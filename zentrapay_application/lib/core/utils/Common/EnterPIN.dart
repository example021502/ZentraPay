import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/features/home/api_home_wallet_services.dart';
import 'api_authentication.dart';

class ConfirmPin extends StatefulWidget {
  const ConfirmPin({super.key, required this.form});

  final Map<String, dynamic> form;

  @override
  State<ConfirmPin> createState() => _ConfirmPinState();
}

class _ConfirmPinState extends State<ConfirmPin> {
  bool visible = false;
  bool loading = false;
  bool replace = false;
  late Map<String, dynamic> _paymentForm;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize your local variable with the widget parameter
    _paymentForm = widget.form;
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed to prevent memory leaks
    _pinController.dispose();
    super.dispose();
  }

  bool success = false;

  void payment() async {
    setState(() {
      loading = true;
    });

    final response = await Authentication(_pinController.text.trim());
    if (!mounted) return;
    if (!response.data["success"]) {
      setState(() {
        loading = false;
      });
      return ZentraNotifier.error(
        "Authentication",
        response.data['message'] ?? "Authentication Failed!",
      );
    }

    try {
      final response = await makeTransfer(_paymentForm);
      if (!mounted) return;

      if (!response?["success"]) {
        setState(() {
          replace = true;
          success = false;
        });
        ZentraNotifier.error("Error", response?['message']);
        print("ERROR:: ${response?['message']}");
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            Navigator.of(context).pop();
          });
        });
      }
      setState(() {
        replace = true;
        success = true;
      });

      Navigator.of(context).pop();
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      // Ensures bottom sheet modal styling is preserved if background overlays exist
      child: Padding(
        padding: EdgeInsets.only(
          // Responsively scales upwards depending on the exact height of the incoming system keyboard
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          // Smoothly animates the UI jump between processing states
          child: loading
              ? Container(
                  key: const ValueKey('loading_state'),
                  padding: const EdgeInsets.all(40),
                  color: AppColors.primary,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      spacing: 50,
                      children: [
                        loading && !replace
                            ? CircularProgressIndicator(
                                color: AppColors.main,
                                strokeWidth: 5,
                                strokeCap: StrokeCap.round,
                              )
                            : success
                            ? Column(
                                children: [
                                  Icon(
                                    Icons.check_circle_sharp,
                                    size: 30,
                                    color: AppColors.green,
                                  ),
                                  Text(
                                    "Transaction was successful!",
                                    style: AppStyles.header.copyWith(
                                      color: AppColors.green,
                                      fontSize: 25,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Icon(
                                    Icons.cancel_sharp,
                                    size: 30,
                                    color: AppColors.main,
                                  ),
                                  Text(
                                    "Transaction Failed!",
                                    style: AppStyles.header.copyWith(
                                      color: AppColors.main,
                                      fontSize: 25,
                                    ),
                                  ),
                                ],
                              ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 220,
                              width: 220,
                              transformAlignment: Alignment.center,
                              transform: Matrix4.rotationZ(0.75),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                color: AppColors.main,
                              ),
                            ),
                            Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                color: AppColors.main,
                              ),
                              child: Center(
                                child: Column(
                                  spacing: 10,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "sending:",
                                          style: AppStyles.text.copyWith(
                                            color: AppColors.primary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          "${_paymentForm["currency_code"] ?? "Code"} ${_paymentForm["amount"] ?? "Amount"}",
                                          style: AppStyles.header.copyWith(
                                            color: AppColors.primary,
                                            fontSize: 20,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),

                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'To:',
                                          style: AppStyles.text.copyWith(
                                            color: AppColors.primary,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          _paymentForm["name"] ?? "N/A",
                                          style: AppStyles.header.copyWith(
                                            color: AppColors.primary,
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
                      ],
                    ),
                  ),
                )
              : Container(
                  key: const ValueKey('input_state'),
                  // Expanded layout parameters safely handle broader viewport width context profiles
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // 1. Wrap content in a Stack to implement floating close button layout rules
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Material(
                      child: Stack(
                        children: [
                          // 2. Main Input Content Panel
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 40,
                              bottom: 20,
                              left: 20,
                              right: 20,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 10,
                              // Ensures modal tightly crops only required spacing profile
                              children: [
                                ListTile(
                                  // Background color of the tile
                                  selectedTileColor: Colors.blue[50],
                                  // Background color when selected is true
                                  shape: RoundedRectangleBorder(
                                    // Gives the tile rounded corners
                                    borderRadius: BorderRadius.circular(10),

                                    // Reduced to clean rectangular pill shape
                                  ),

                                  // Padding and Spacing
                                  contentPadding: const EdgeInsets.symmetric(
                                    // Internal padding for contents
                                    horizontal: 15.0,
                                    vertical: 5.0,
                                  ),
                                  horizontalTitleGap: 10.0,
                                  // Clean icon-to-title gap spacing
                                  // Space between leading icon and title
                                  minVerticalPadding: 15.0,
                                  // Minimum padding above/below text

                                  // Alignment
                                  titleAlignment: ListTileTitleAlignment.center,
                                  dense: false,
                                  leading: Icon(
                                    Icons.person,
                                    size: 30,
                                    color: AppColors.secondary,
                                  ),
                                  title: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: [
                                      Text("Send:", style: AppStyles.text),
                                      Text(
                                        "${_paymentForm["currency_code"] ?? "code"} ${_paymentForm["amount"] ?? "amount"}",
                                        style: AppStyles.header,
                                      ),
                                      Text("To:", style: AppStyles.text),
                                      Text(
                                        _paymentForm["name"] ?? "N/A",
                                        style: AppStyles.header,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Enter Your PIN",
                                      style: AppStyles.text,
                                    ),
                                    TextField(
                                      controller: _pinController,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      obscureText: !visible,
                                      decoration: InputDecoration(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 15,
                                              horizontal: 20,
                                            ),
                                        suffixIcon: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              visible = !visible;
                                            });
                                          },
                                          child: Icon(
                                            visible
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                          ),
                                        ),
                                        border: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColors.secondary,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: const OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(10),
                                          ),
                                          borderSide: BorderSide(
                                            color: AppColors.secondary,
                                            width: 1,
                                          ),
                                        ),
                                        labelText: 'PIN',
                                      ),
                                      onSubmitted: (value) {
                                        if (value.isNotEmpty) {
                                          setState(() {
                                            loading = true;
                                          });
                                          // Mimic action handling block profiles safely here
                                          Future.delayed(
                                            const Duration(seconds: 2),
                                            () {
                                              setState(() {
                                                loading = false;
                                              });
                                              if (!mounted) return;
                                              Navigator.of(context).pop(true);
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 25),

                                // Cleaned up Row layout using standardized button mechanics to handle sizing gracefully
                                SizedBox(
                                  width: double.infinity,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: loading
                                          ? AppColors.secondary.withAlpha(60)
                                          : AppColors.secondary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: InkWell(
                                      onTap: () async {
                                        if (loading) return;
                                        payment();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Center(
                                          child: Text(
                                            "Send",
                                            style: AppStyles.header.copyWith(
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 3. Floating Close/Cancel Button Layer anchored to the Top-Right Corner
                          Positioned(
                            top: 15,
                            right: 15,
                            child: FloatingActionButton.small(
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                              backgroundColor: AppColors.primary,
                              elevation: 2,
                              shape: const CircleBorder(),
                              child: Icon(
                                Icons.close,
                                color: AppColors.main,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
