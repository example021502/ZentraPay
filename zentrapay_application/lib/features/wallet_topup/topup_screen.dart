import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/wallet_topup/models/responseEntities.dart';
import 'package:zentrapay_application/features/wallet_topup/topup_service.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart';

// Comment: Updated _TopupScreenState class handling data initialization, state management, and side-by-side dropdown selectors.
class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Currency selection
  SupportedCurrencies? _selectedCurrency;
  bool _isCurrencyLoaded = false;
  bool _isSourcesLoaded = false;
  List<SupportedCurrencies> _availableCurrencies = [];
  FundingSources? _sources;

  // Payment state
  String? _accessCode;
  String? _gatewayUsed;
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedSource;
  String? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  // Comment: Load available currencies and funding sources from backend services on startup
  Future<void> _initialLoad() async {
    final wallet = WalletsRepository.instance;
    final zgrow = FundingSourcesRepository.instance;
    zgrow.ensureLoaded();

    setState(() {
      _isLoading = true;
    });
    try {
      _availableCurrencies = await wallet.getSupportedCurrencies();
      _sources = zgrow.data;

      setState(() {
        _isCurrencyLoaded = _availableCurrencies.isNotEmpty;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isCurrencyLoaded = false;
      });
    }
  }

  Future<void> _continuePressed() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      setState(() => _errorMessage = 'Please enter an amount');
      return;
    }

    final currencyCode = _selectedCurrency?.currencyCode;
    if (currencyCode == null) {
      setState(() {
        _errorMessage = "Currency code missing";
      });
      return;
    }

    if (_selectedMethod == null || _selectedMethod!.isEmpty) {
      setState(() {
        _errorMessage = "Select Method";
      });
      return;
    }
    if (_selectedSource == null || _selectedSource!.isEmpty) {
      setState(() {
        _errorMessage = "Select Source";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _accessCode = null;
      _gatewayUsed = null;
    });

    String? accessCode;
    String? gatewayUsed;

    try {
      TopupResponse paystackResponse = await TopupService.topup(
        amount: double.parse(amount),
        currencyCode: currencyCode,
        gateway: "paystack",
        source: _selectedSource!,
        paymentMethod: _selectedMethod!,
      );
      if (paystackResponse.status) {
        accessCode = paystackResponse.accessCode;
        gatewayUsed =
            paystackResponse.gatewayData?['name'].toLowerCase() ?? 'paystack';
      }
    } catch (e) {
      debugPrint('Paystack top up failed, trying fallback: $e');
      try {
        TopupResponse flutterwaveResponse = await TopupService.topup(
          amount: double.parse(amount),
          currencyCode: currencyCode,
          gateway: "flutterwave",
          source: _selectedSource!,
          paymentMethod: _selectedMethod!,
        );
        if (flutterwaveResponse.status) {
          accessCode = flutterwaveResponse.accessCode;
          gatewayUsed =
              flutterwaveResponse.gatewayData?['name'].toLowerCase() ??
              'flutterwave';
        }
      } catch (err) {
        debugPrint('All top up attempts failed: $err');
      }
    }

    if (accessCode != null && accessCode.isNotEmpty) {
      setState(() {
        _accessCode = accessCode;
        _gatewayUsed = gatewayUsed;
        _isLoading = false;
      });
      await _openGatewaySdk(accessCode: accessCode, gateway: gatewayUsed!);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to obtain access code from gateway';
      });
    }
  }

  Future<void> _openGatewaySdk({
    required String accessCode,
    required String gateway,
  }) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $gateway payment interface...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppTheme.spacingLg,
        children: [
          _buildAmountField(theme),
          _sourceAndMethodFields(theme),
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
    );
  }

  Widget _buildAmountField(ThemeData theme) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount',
        labelStyle: AppTheme.bodyLarge,
        hintText: 'Enter amount (e.g., 100.00)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        suffix: _isCurrencyLoaded
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.25,
                ),
                child: PopupMenuButton<SupportedCurrencies>(
                  color: AppTheme.gray100,
                  elevation: 4,
                  onSelected: (SupportedCurrencies currency) {
                    setState(() {
                      _selectedCurrency = currency;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return _availableCurrencies.map((
                      SupportedCurrencies currency,
                    ) {
                      return PopupMenuItem<SupportedCurrencies>(
                        value: currency,
                        child: Text(
                          currency.currencyCode,
                          style: AppTheme.labelLarge,
                        ),
                      );
                    }).toList();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCurrency?.currencyCode ??
                            _availableCurrencies[0].currencyCode,
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }

  // Comment: Widget displaying funding source and payment method side-by-side in a Row
  Widget _sourceAndMethodFields(ThemeData theme) {
    return Row(
      children: [
        // Comment: 1. Funding Source Dropdown taking 50% width
        Expanded(
          child: PopupMenuButton<FundingSource>(
            color: AppTheme.gray100,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            onSelected: (FundingSource source) {
              setState(() {
                _selectedSource = source.name;
                _selectedMethod = source
                    .method; // Comment: Automatically auto-populate payment method
              });
            },
            itemBuilder: (BuildContext context) {
              return _isSourcesLoaded && _sources != null
                  ? _sources!.sources.map((FundingSource source) {
                      return PopupMenuItem<FundingSource>(
                        value: source,
                        child: Text(source.name, style: AppTheme.labelLarge),
                      );
                    }).toList()
                  : [
                      const PopupMenuItem<FundingSource>(
                        enabled: false,
                        child: Text('Loading sources...'),
                      ),
                    ];
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Funding Source',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: AppTheme.gray300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedSource ?? 'Select Source',
                      style: AppTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: AppTheme.spacingMd),

        // Comment: 2. Payment Method Display taking 50% width (auto-populated from source)
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Payment Method',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.gray300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedMethod ?? 'Auto-selected',
                    style: AppTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
