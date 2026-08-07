// Always put comments on all responses.
import 'dart:async';

import 'package:country_flags/country_flags.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

import 'package:zentrapay_application/features/home/getCurrencyISOCodeHelper.dart';
import 'package:zentrapay_application/core/repositories/payment_channels_repository.dart';
import 'package:zentrapay_application/core/utils/Common/AppPinSheet.dart';

/// External Payment Screen
///
/// This screen handles external payments to bank accounts via Paystack.
/// External payments are transactions to accounts outside ZentraPay.
///
/// @description UI for initiating and managing external bank transfers with inline debounced bank search
/// @version 1.1.2
/// @author ZentraPay Team

class ExternalPaymentScreen extends StatefulWidget {
  const ExternalPaymentScreen({super.key});

  @override
  State<ExternalPaymentScreen> createState() => _ExternalPaymentScreenState();
}

class _ExternalPaymentScreenState extends State<ExternalPaymentScreen> {
  // Form controllers
  final _accountNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _bankSearchController = TextEditingController();

  // Debounce tracking timer
  Timer? _debounceTimer;

  // State variables
  List<Map<String, dynamic>> _filteredBanks = [];
  bool _isLoading = false;
  bool _isLoadingBanks = false;
  bool _showDropdown = false;
  String? _errorMessage;

  Map<String, dynamic> paymentDetails = {
    "bank_name": "",
    "bank_code": "",
    "account_name": "",
    "account_number": "",
    "amount": 0.00,
    "currency_code": "GHS",
    "type": "",
    "description": "",
    "receiver_country": "",
  };

  String? country = '';
  String _countryFlag = "GH";

  @override
  void initState() {
    super.initState();
  }

  /// Debounced network fetch handler
  /// @description Destroys the existing timer and starts a 500ms countdown on each keystroke
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _filteredBanks = [];
          _showDropdown = false;
        });
      }
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchBanksFromServer(query.trim());
    });
  }

  /// Query the backend server dynamically matching the searched bank keyword
  Future<void> _fetchBanksFromServer(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoadingBanks = true;
      _errorMessage = null;
      _showDropdown = true;
    });

    try {
      final channels = await PaymentChannelsRepository.instance.load(
        countryCode: _countryFlag,
        type: 'BANK',
      );
      final allBanks = channels
          .map(
            (c) => {
              'name': c.channelName,
              'code': c.channelCode,
              'country': c.countryCode,
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          _filteredBanks = allBanks
              .where(
                (bank) =>
                    bank['name'].toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    bank['code'].toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
          _isLoadingBanks = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error retrieving banks: ${e.toString()}';
          _isLoadingBanks = false;
        });
      }
    }
  }

  Future<void> _initializePayment() async {
    if (!_validateForm()) return;

    setState(() {
      paymentDetails['account_name'] = _accountNameController.text.trim();
      paymentDetails['account_number'] = _accountNumberController.text.trim();
      paymentDetails['description'] = _descriptionController.text.trim();
      _isLoading = true;
      _errorMessage = null;
    });

    setState(() => _isLoading = false);
    if (!mounted) return;

    final form = {
      'recipientType': 'external-bank',
      'channelCode': paymentDetails['bank_code'],
      'accountNumber': paymentDetails['account_number'],
      'accountName': paymentDetails['account_name'],
      'amount': paymentDetails['amount'].toString(),
      'currency_code': paymentDetails['currency_code'],
      'description': (paymentDetails['description'] as String).isEmpty
          ? null
          : paymentDetails['description'],
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AppPinSheet.confirmTransaction(form: form),
    );
  }

  bool _validateForm() {
    if (paymentDetails['bank_name'] == "" ||
        paymentDetails['bank_code'] == "") {
      _showError('Please search and select a valid Bank');
      return false;
    }
    if (_accountNumberController.text.isEmpty ||
        _accountNumberController.text.length < 10) {
      _showError('Please enter a valid account number');
      return false;
    }
    if (_accountNameController.text.trim().isEmpty) {
      _showError('Please enter the Account Name');
      return false;
    }
    if (paymentDetails['amount'] <= 0) {
      _showError('Please enter a valid amount');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        padding: const EdgeInsets.all(2),
        showCloseIcon: true,
        closeIconColor: AppTheme.primaryWhite,
        backgroundColor: AppTheme.primaryPink,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryPink,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: AppTheme.primaryWhite,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Send To Bank',
          style: TextStyle(color: AppTheme.primaryWhite, fontSize: 18),
        ),
      ),
      // Cleaned up body structure to remove restrictive IntrinsicHeight calculations entirely
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
        child: Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Safe layout rendering for textfield coupled list elements
            _buildInlineBankSearchWithDropdown(),

            _buildTextField(
              controller: _accountNameController,
              label: 'Account Name',
              hint: 'Enter bank account name',
              icon: Icons.person_2_outlined,
            ),

            _buildTextField(
              controller: _accountNumberController,
              label: 'Account Number',
              hint: 'Enter bank account number',
              icon: Icons.account_balance_wallet_outlined,
              keyboardType: TextInputType.number,
            ),

            _buildAmountField(),

            _buildTextField(
              controller: _descriptionController,
              label: 'Description (Optional)',
              hint: 'Enter payment description',
              icon: Icons.description_outlined,
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _initializePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: AppTheme.secondaryNavy,
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryWhite,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    bool isDescription = label == 'Description (Optional)';
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: isDescription ? null : 1,
      minLines: isDescription ? 3 : 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        contentPadding: const EdgeInsets.all(15),
        prefixIcon: Icon(icon, color: AppTheme.textBlack),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.gray300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppTheme.secondaryNavy,
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextField(
      onChanged: (amount) {
        setState(() {
          paymentDetails['amount'] = double.tryParse(amount) ?? 0.00;
        });
      },
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        DecimalTextInputFormatter(),
      ],
      decoration: InputDecoration(
        labelText: 'Amount',
        hintText: '0.00',
        contentPadding: const EdgeInsets.all(15),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppTheme.secondaryNavy,
            width: 1,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.gray300),
        ),
        prefixIcon: GestureDetector(
          onTap: () => showCurrencyPicker(
            context: context,
            showFlag: true,
            showCurrencyName: true,
            showCurrencyCode: true,
            onSelect: (Currency currency) {
              String isoCode = extractCountryIsoCode(currency.code);
              setState(() {
                paymentDetails['currency_code'] = currency.code;
                _countryFlag = isoCode;
              });
            },
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 10),
              const Icon(
                Icons.arrow_drop_down,
                color: AppTheme.textBlack,
              ),
              const SizedBox(width: 4),
              CountryFlag.fromCountryCode(
                _countryFlag,
                shape: const Circle(),
                height: 24,
                width: 24,
              ),
              const SizedBox(width: 8),
              Text(
                paymentDetails['currency_code'],
                style: const TextStyle(
                  color: AppTheme.textBlack,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }

  /// Combined Search and Menu dropdown component layout
  /// @description Safe linear rendering layout for the dropdown block inside our dynamic layout scope
  Widget _buildInlineBankSearchWithDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _bankSearchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            labelText: 'Bank Name',
            hintText: 'Type bank name or code',
            contentPadding: const EdgeInsets.all(15),
            prefixIcon: const Icon(
              Icons.account_balance_outlined,
              color: AppTheme.textBlack,
            ),
            suffixIcon: _isLoadingBanks
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryPink,
                      ),
                    ),
                  )
                : _bankSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _bankSearchController.clear();
                      setState(() {
                        paymentDetails['bank_name'] = "";
                        paymentDetails['bank_code'] = "";
                        paymentDetails['type'] = "";
                        _filteredBanks = [];
                        _showDropdown = false;
                      });
                    },
                  )
                : const Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.textBlack,
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppTheme.gray300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppTheme.secondaryNavy,
                width: 1,
              ),
            ),
          ),
        ),

        if (_errorMessage != null && !_showDropdown)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppTheme.primaryPink, fontSize: 12),
            ),
          ),

        // Normal conditional statement is now completely safe because IntrinsicHeight was removed
        if (_showDropdown)
          Container(
            clipBehavior: Clip.antiAlias,
            constraints: const BoxConstraints(maxHeight: 250),
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: AppTheme.primaryWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _filteredBanks.isEmpty && !_isLoadingBanks
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No matching banks found.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.all(10),
                    itemCount: _filteredBanks.length,
                    itemBuilder: (context, index) {
                      final bank = _filteredBanks[index];
                      final isSelected =
                          paymentDetails['bank_code'] == bank['code'];

                      return Material(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: ListTile(
                            leading: Icon(
                              Icons.account_balance_outlined,
                              size: 20,
                              color: AppTheme.textBlack,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: AppTheme.gray300
                                    .withAlpha(50),
                              ),
                            ),
                            tileColor: isSelected
                                ? AppTheme.primaryPink.withAlpha(10)
                                : AppTheme.secondaryNavy.withAlpha(
                                    10,
                                  ),
                            title: Text(
                              bank['name'] ?? 'Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Code: ${bank['code'] ?? ''} | ${bank['country'] ?? ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: () {
                              setState(() {
                                paymentDetails['bank_code'] = bank['code'];
                                paymentDetails['bank_name'] = bank['name'];
                                paymentDetails['type'] = bank['type'];
                                paymentDetails['receiver_country'] =
                                    bank['country'];
                                _bankSearchController.text = bank['name'];
                                _showDropdown = false;
                              });
                              FocusScope.of(context).unfocus();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _accountNumberController.dispose();
    _descriptionController.dispose();
    _accountNameController.dispose();
    _bankSearchController.dispose();
    super.dispose();
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(
        text: "0.00",
        selection: const TextSelection.collapsed(offset: 4),
      );
    }

    double value = double.tryParse(newValue.text) ?? 0.00;
    final formatter = NumberFormat("0.00", "en_US");
    String newText = formatter.format(value / 100);

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
