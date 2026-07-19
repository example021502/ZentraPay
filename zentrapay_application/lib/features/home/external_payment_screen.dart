// Always put comments on all responses.
import 'dart:async';

import 'package:country_flags/country_flags.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';

import 'package:zentrapay_application/features/home/getCurrencyISOCodeHelper.dart';
import 'external_payment_service.dart';

/**
 * External Payment Screen
 *
 * This screen handles external payments to bank accounts via Paystack.
 * External payments are transactions to accounts outside ZentraPay.
 *
 * @description UI for initiating and managing external bank transfers with inline debounced bank search
 * @version 1.1.2
 * @author ZentraPay Team
 */

class _ExternalPaymentColors {
  static const Color main = Color(0xFFF21773);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color textBlack = Color(0xFF000000);
  static const Color green = Color(0xFF06881C);
  static const Color lightGrey = Color(0x80808080);
  static const Color secondary = Color(0xFF210163);
}

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

  final ExternalPaymentService _paymentService = ExternalPaymentService();

  @override
  void initState() {
    super.initState();
  }

  /**
   * Debounced network fetch handler
   * @description Destroys the existing timer and starts a 500ms countdown on each keystroke
   */
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

  /**
   * Query the backend server dynamically matching the searched bank keyword
   */
  Future<void> _fetchBanksFromServer(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoadingBanks = true;
      _errorMessage = null;
      _showDropdown = true;
    });

    try {
      final response = await _paymentService.getSupportedBanks();

      if (response['success'] == true) {
        final allBanks = List<Map<String, dynamic>>.from(response['data']);

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
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Failed to match banks';
            _isLoadingBanks = false;
          });
        }
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

    try {
      final response = await _paymentService.initializeExternalPayment(
        paymentData: paymentDetails,
      );
      if (response?['success'] == true) {
        if (mounted) {
          _showPaymentOptions(response?['data']);
        }
      } else {
        setState(() {
          ZentraNotifier.error("Error", response?['message']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
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
        closeIconColor: AppColors.primary,
        backgroundColor: _ExternalPaymentColors.main,
      ),
    );
  }

  void _showPaymentOptions(Map<String, dynamic> paymentData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Initialized'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount: ${paymentDetails['currency_code']} ${paymentData['amount']}',
            ),
            Text('Reference: ${paymentData['reference']}'),
            const SizedBox(height: 16),
            const Text('Please complete the payment to proceed.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openPaymentUrl(paymentData['authorization_url']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _ExternalPaymentColors.main,
            ),
            child: const Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  void _openPaymentUrl(String url) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening payment gateway...'),
        backgroundColor: _ExternalPaymentColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ExternalPaymentColors.primary,
      appBar: AppBar(
        backgroundColor: _ExternalPaymentColors.main,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left,
            color: _ExternalPaymentColors.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Send To Bank',
          style: TextStyle(color: _ExternalPaymentColors.primary, fontSize: 18),
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
                  backgroundColor: _ExternalPaymentColors.main,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: _ExternalPaymentColors.secondary,
                      )
                    : const Text(
                        'Pay Now',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _ExternalPaymentColors.primary,
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
        prefixIcon: Icon(icon, color: _ExternalPaymentColors.textBlack),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _ExternalPaymentColors.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: _ExternalPaymentColors.secondary,
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
            color: _ExternalPaymentColors.secondary,
            width: 1,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _ExternalPaymentColors.lightGrey),
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
                color: _ExternalPaymentColors.textBlack,
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
                  color: _ExternalPaymentColors.textBlack,
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

  /**
   * Combined Search and Menu dropdown component layout
   * @description Safe linear rendering layout for the dropdown block inside our dynamic layout scope
   */
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
              color: _ExternalPaymentColors.textBlack,
            ),
            suffixIcon: _isLoadingBanks
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _ExternalPaymentColors.main,
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
                    color: _ExternalPaymentColors.textBlack,
                  ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: _ExternalPaymentColors.lightGrey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: _ExternalPaymentColors.secondary,
                width: 1,
              ),
            ),
          ),
        ),

        // Normal conditional statement is now completely safe because IntrinsicHeight was removed
        if (_showDropdown)
          Container(
            clipBehavior: Clip.antiAlias,
            constraints: const BoxConstraints(maxHeight: 250),
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: _ExternalPaymentColors.primary,
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
                              color: AppColors.textBlack,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: _ExternalPaymentColors.lightGrey
                                    .withAlpha(50),
                              ),
                            ),
                            tileColor: isSelected
                                ? _ExternalPaymentColors.main.withAlpha(10)
                                : _ExternalPaymentColors.secondary.withAlpha(
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
