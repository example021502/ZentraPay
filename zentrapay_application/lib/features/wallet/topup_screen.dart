import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/wallet/models/responseEntities.dart';
import 'package:zentrapay_application/features/wallet/topup_service.dart';

/// Screen for topping up wallet with currency selection and payment gateway integration.
class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _currencyCodeController = TextEditingController(
    text: "GHS : Ghanian Cedi",
  );

  // Currency selection
  SupportedCurrencies? _selectedCurrency;
  bool _isCurrencyLoaded = false;
  List<SupportedCurrencies> _availableCurrencies = [];

  // Payment state
  String? _accessCode;
  String? _gatewayUsed; // 'paystack' or 'flutterwave'
  bool _isLoading = false;
  String? _errorMessage;

  String selectedSource = "BANK";
  String selectedPaymentMethod = "BANK_TRANSFER";

  @override
  void initState() {
    super.initState();
    _currencyCodeController.dispose();
    _amountController.dispose();
    _loadCurrencies();
  }

  /// Load available currencies from the backend API
  Future<void> _loadCurrencies() async {
    final wallet = WalletsRepository.instance;
    setState(() {
      _isLoading = true;
    });
    _availableCurrencies = await wallet.getSupportedCurrencies();
    setState(() {
      _isCurrencyLoaded = wallet.isLoaded;
      _isLoading = wallet.isLoading;
    });
  }

  /// Validate and start the topup process
  Future<void> _continuePressed() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      setState(() => _errorMessage = 'Please enter an amount');
      return;
    }

    // Ensure a currency is selected
    final currencyCode =
        _selectedCurrency?.currencyCode ?? _currencyCodeController.text.trim();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _accessCode = null;
      _gatewayUsed = null;
    });

    // Try Paystack first (primary gateway), then Flutterwave (secondary)
    String? accessCode;
    String? gatewayUsed;

    /////    USING THE TOP UP SERVICE API CALL IN THE TOP UP SERVICE FILE...
    try {
      // Attempt 1: Paystack access code
      TopupResponse paystackResponse = await TopupService.topup(
        amount: double.parse(amount),
        currencyCode: currencyCode,
        gateway: "paystack",
        source: selectedSource,
        paymentMethod: selectedPaymentMethod,
      );
      print("THE PAYSTACK TOPUP RESULTS ARE:: $paystackResponse");
      if (paystackResponse.status) {
        accessCode = paystackResponse.accessCode;
        gatewayUsed =
            paystackResponse.gatewayData?['name'].toLowerCase() ?? 'paystack';
        debugPrint(
          'Paystack access code response: ${paystackResponse.accessCode}',
        );
      }
    } catch (e) {
      debugPrint('Top up failed. $e');
      try {
        TopupResponse flutterwaveResponse = await TopupService.topup(
          amount: double.parse(amount),
          currencyCode: currencyCode,
          gateway: "paystack",
          source: selectedSource,
          paymentMethod: selectedPaymentMethod,
        );
        print("THE FLUTTERWAVE TOPUP RESULTS ARE:: $flutterwaveResponse");
        if (flutterwaveResponse.status) {
          accessCode = flutterwaveResponse.accessCode;
          gatewayUsed =
              flutterwaveResponse.gatewayData?['name'].toLowerCase() ??
              'paystack';
          debugPrint(
            'Paystack access code response: ${flutterwaveResponse.accessCode}',
          );
        }
      } catch (e) {
        debugPrint('Top up failed. $e');
      }
    }

    if (accessCode != null && accessCode.isNotEmpty) {
      // Successfully obtained access code - open the respective SDK
      setState(() {
        _accessCode = accessCode;
        _gatewayUsed = gatewayUsed;
      });

      // Open the appropriate frontend SDK
      await _openGatewaySdk(accessCode: accessCode, gateway: gatewayUsed!);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to obtain access code from gateway';
      });
    }
  }

  /// Open the respective frontend SDK with the access code
  Future<void> _openGatewaySdk({
    required String accessCode,
    required String gateway,
  }) async {
    if (gateway == 'paystack') {
      if (!mounted) return;

      if (kDebugMode) {
        debugPrint('Paystack SDK would be opened with access code: ');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening Paystack payment interface... (access code: )',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (gateway == 'flutterwave') {
      if (!mounted) return;

      if (kDebugMode) {
        debugPrint('Flutterwave SDK would be opened with access code: ');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Opening Flutterwave payment interface... (access code: )',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Top Up Wallet',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.primaryWhite),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount input
              _buildAmountField(theme),

              const SizedBox(height: 24),

              // Currency selection - only show if currencies are loaded
              if (_isCurrencyLoaded)
                InkWell(
                  onTap: () => showCurrencies(context),
                  splashColor: Colors.transparent,
                  child: TextField(
                    controller: _currencyCodeController,
                    enabled: false,
                    decoration: InputDecoration(
                      fillColor: AppTheme.gray100,
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.gray300),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),

                      suffixIcon: Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: AppTheme.textBlack,
                      ),
                    ),
                  ),
                ),

              // Continue button
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ElevatedButton(
                      onPressed: _continuePressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16.0),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Continue'),
                    ),

              const SizedBox(height: 32),

              // Error/message display
              if (_errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build the amount text field
  Widget _buildAmountField(ThemeData theme) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount',
        hintText: 'Enter amount (e.g., 100.00)',
        prefixText: ' ',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppTheme.focusFieldColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid positive amount';
        }
        return null;
      },
    );
  }

  void showCurrencies(BuildContext context) {
    // Comment: Replacing the bottom sheet method with a PopupMenuButton widget implementation.
    PopupMenuButton<SupportedCurrencies>(
      // Comment: The trigger icon or button that grows the popup menu
      icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryWhite),

      // Comment: Styling the popup container background and shape
      color: AppTheme.darkBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),

      // Comment: Triggered when the user taps an item in the popup list
      onSelected: (SupportedCurrencies currency) {
        setState(() {
          // Comment: Update the text controller and refresh the UI state
          _currencyCodeController.text = currency.currencyCode;
        });
      },

      // Comment: Dynamically build the popup menu items from the available currencies list
      itemBuilder: (BuildContext context) {
        return _availableCurrencies.map((SupportedCurrencies currency) {
          return PopupMenuItem<SupportedCurrencies>(
            value: currency,
            child: Text(
              "${currency.currencyCode} ${currency.currencyName}",
              style: AppTheme.bodyMedium,
            ),
          );
        }).toList();
      },
    );
  }
}
