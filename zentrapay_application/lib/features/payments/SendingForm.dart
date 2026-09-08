import 'dart:async';

import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/core/models/reference_data.dart';
import 'package:zentrapay_application/features/home/repository/cache_homeData.dart';
import 'package:zentrapay_application/features/payments/repository/cache_paymentsData.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profileData.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/AppConfirmSheet.dart';
import 'package:zentrapay_application/core/utils/Common/TransactionResultOverlay.dart';
import 'package:zentrapay_application/core/utils/LoadingOverlay.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';

import 'Op_Button.dart';

class SendingForm extends StatefulWidget {
  const SendingForm({super.key});

  @override
  State<SendingForm> createState() => _SendingFormState();
}

class _SendingFormState extends State<SendingForm> {
  // Fix 1: Move country_state inside the State object so it manages lifecycles correctly

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  String target = "wallet";
  Currency? selectedCurrency;

  // ------------------------------------------------------------------
  // Bank-transfer state — the picker/resolve/submit flow lives here since
  // it needs the payment-channels directory and the sender's own
  // registration country (for the channel list), neither of which the
  // wallet tab needs.
  // ------------------------------------------------------------------
  List<PaymentChannel> _banks = [];
  PaymentChannel? _selectedBank;
  bool _loadingBanks = false;
  bool _resolvingAccount = false;
  String? _resolvedAccountName;
  Timer? _resolveDebounce;
  bool _sendInFlight = false;

  Map<String, String> formData = {
    "recipient_name": "",
    "amount": "",
    "payout_option": "",
    "contact_number": "",
    "country": "",
    "account_number": "",
  };

  @override
  void initState() {
    super.initState();
    _loadBanks();
    _bankController.addListener(_onAccountNumberChanged);
  }

  Future<void> _loadBanks() async {
    setState(() => _loadingBanks = true);
    try {
      final countryCode =
          UserProfileRepository.instance.user?.countryCode ?? "GH";
      final banks = await PaymentChannelsRepository.instance.load(
        countryCode: countryCode,
        type: "BANK",
      );
      if (!mounted) return;
      setState(() => _banks = banks);
    } catch (e) {
      debugPrint("Failed to load bank directory: $e");
    } finally {
      if (mounted) setState(() => _loadingBanks = false);
    }
  }

  void _onAccountNumberChanged() {
    _resolveDebounce?.cancel();
    setState(() => _resolvedAccountName = null);
    final accountNumber = _bankController.text.trim();
    if (_selectedBank == null || accountNumber.length < 6) return;

    _resolveDebounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _resolvingAccount = true);
      try {
        final name = await PaymentChannelsRepository.instance
            .resolveAccountName(
              channelCode: _selectedBank!.channelCode,
              accountNumber: accountNumber,
            );
        if (!mounted) return;
        setState(() {
          _resolvedAccountName = name;
          if (name != null && name.isNotEmpty) {
            _nameController.text = name;
          }
        });
      } catch (e) {
        debugPrint("Account resolve failed: $e");
        if (mounted) {
          ZentraNotifier.error(
            "Could not verify account",
            "Double check the bank and account number.",
          );
        }
      } finally {
        if (mounted) setState(() => _resolvingAccount = false);
      }
    });
  }

  void onChange(String id, var value) {
    setState(() {
      id == "contact_number"
          ? (
              formData[id] = value.phone,
              formData['country'] = value.countryName,
            )
          : formData[id] = value;
    });
  }

  Future<void> _submitBankTransfer() async {
    if (_sendInFlight) return;
    if (_selectedBank == null) {
      ZentraNotifier.error("Select a bank", "Choose a destination bank first.");
      return;
    }
    if (_bankController.text.trim().isEmpty) {
      ZentraNotifier.error("Account number required", "Enter the recipient's account number.");
      return;
    }
    if (selectedCurrency == null || _amountController.text.trim().isEmpty) {
      ZentraNotifier.error("Amount required", "Enter how much to send.");
      return;
    }
    final accountName = _resolvedAccountName ?? _nameController.text.trim();
    if (accountName.isEmpty) {
      ZentraNotifier.error("Account name required", "Could not verify the account holder's name.");
      return;
    }

    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AppConfirmPinSheet(
        name: accountName,
        currencyCode: selectedCurrency!.code,
        amount: _amountController.text.trim(),
        destination: _selectedBank!.channelName,
      ),
    );
    if (pin == null || pin.isEmpty || !mounted) return;

    setState(() => _sendInFlight = true);
    try {
      final amountText = _amountController.text.trim();
      final currencyCode = selectedCurrency!.code;
      final transaction = await LoadingOverlay.run(
        () => PaymentsService.payBankTransfer(
          pin: pin,
          amount: amountText,
          currencyCode: currencyCode,
          channelCode: _selectedBank!.channelCode,
          accountNumber: _bankController.text.trim(),
          accountName: accountName,
        ),
        message: "Processing transfer…",
      );
      if (!mounted) return;
      await showTransactionResultOverlay(
        context: context,
        status: TransactionResultStatus.success,
        title: "Transfer Submitted",
        message: "$currencyCode $amountText to $accountName is processing.",
        details: [
          TransactionResultDetail("Recipient", accountName),
          TransactionResultDetail("Bank", _selectedBank!.channelName),
          TransactionResultDetail("Amount", "$currencyCode $amountText"),
          TransactionResultDetail("Reference", transaction.transactionId),
        ],
      );
      if (!mounted) return;
      _bankController.clear();
      _amountController.clear();
      _nameController.clear();
      setState(() {
        _selectedBank = null;
        _resolvedAccountName = null;
      });
    } catch (e) {
      if (!mounted) return;
      await showTransactionResultOverlay(
        context: context,
        status: TransactionResultStatus.error,
        title: "Transfer Failed",
        message: _extractErrorMessage(e),
      );
    } finally {
      if (mounted) setState(() => _sendInFlight = false);
    }
  }

  String _extractErrorMessage(Object e) {
    final message = e.toString();
    return message.contains("DioException")
        ? "Something went wrong. Please try again."
        : message;
  }

  @override
  void dispose() {
    // Clean up all individual text field controllers
    _resolveDebounce?.cancel();
    _bankController.removeListener(_onAccountNumberChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _bankController.dispose();
    _amountController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text("Send To:", style: AppStyles.header),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: Duration(milliseconds: 400),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(40),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Op_Button(
                      label: "Wallet",
                      icn: Icons.person,
                      isActive: target == "wallet",
                      onSelect: () {
                        setState(() {
                          target = "wallet";
                        });
                      },
                    ),
                  ),
                  // Adds a clean gap between stretched layouts
                  Expanded(
                    child: Op_Button(
                      label: "Bank",
                      icn: Icons.account_balance_outlined,
                      isActive: target == "bank",
                      onSelect: () {
                        setState(() {
                          target = "bank";
                        });
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20, horizontal: 15),
                child: target == "wallet" ? _wallet_form() : _bank_form(),
              ),
              GestureDetector(
                onTap: target == "bank" ? _submitBankTransfer : () {},
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryNavy,
                    borderRadius: BorderRadius.circular(200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      if (_sendInFlight)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryWhite,
                          ),
                        )
                      else ...[
                        Text(
                          "Send Now",
                          style: AppStyles.header.copyWith(
                            color: AppTheme.primaryWhite,
                          ),
                        ),
                        Icon(Icons.send, color: AppTheme.primaryWhite, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _wallet_form() {
    return Column(
      spacing: 20,
      children: [
        _textField(
          label: "Full name",
          controller: _nameController,
          isPhoneField: false,
          isAmount: false,
          id: "recipient_name",
          onValueChanging: onChange,
        ),
        _textField(
          label: "Contact Number",
          controller: _phoneController,
          isPhoneField: true,
          isAmount: false,
          id: "contact_number",
          onValueChanging: onChange,
        ),
        _textField(
          label: "Enter Amount",
          controller: _amountController,
          isPhoneField: false,
          isAmount: true,
          id: "amount",
          onValueChanging: onChange,
        ),
      ],
    );
  }

  Widget _bank_form() {
    return Column(
      spacing: 20,
      children: [
        _bankPicker(),
        _textField(
          label: "Bank Ac. No. / IBAN ",
          controller: _bankController,
          isPhoneField: false,
          isAmount: false,
          id: "account_number",
          onValueChanging: onChange,
        ),
        if (_resolvingAccount)
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (_resolvedAccountName != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _resolvedAccountName!,
              style: AppStyles.header.copyWith(color: AppTheme.successGreen),
            ),
          ),
        _textField(
          label: "Recipient Full name",
          controller: _nameController,
          isPhoneField: false,
          isAmount: false,
          id: "recipient_name",
          onValueChanging: onChange,
        ),
        _textField(
          label: "Enter Amount",
          controller: _amountController,
          isPhoneField: false,
          isAmount: true,
          id: "amount",
          onValueChanging: onChange,
        ),
      ],
    );
  }

  /// Bank/mobile-money destination picker, backed by the payment-channels
  /// directory for the sender's own registration country.
  Widget _bankPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(200),
        border: Border.all(color: AppTheme.lightGrey, width: 0.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<PaymentChannel>(
          isExpanded: true,
          value: _selectedBank,
          hint: Text(
            _loadingBanks ? "Loading banks..." : "Select bank",
            style: AppStyles.text,
          ),
          items: _banks
              .map(
                (bank) => DropdownMenuItem(
                  value: bank,
                  child: Text(bank.channelName),
                ),
              )
              .toList(),
          onChanged: _loadingBanks
              ? null
              : (bank) {
                  setState(() {
                    _selectedBank = bank;
                    _resolvedAccountName = null;
                  });
                  _onAccountNumberChanged();
                },
        ),
      ),
    );
  }

  // Refactored reusable text field layout components
  Widget _textField({
    required String label,
    required TextEditingController controller,
    required bool isPhoneField,
    required bool isAmount,
    required String id,
    required Function onValueChanging,
  }) {
    return isPhoneField
        ? IntlPhoneField(
            controller: controller,
            dropdownDecoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            decoration: InputDecoration(
              labelText: label,
              fillColor: AppTheme.primaryWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(200),
                borderSide: BorderSide(color: AppTheme.lightGrey, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(200),
                borderSide: BorderSide(color: AppTheme.lightGrey, width: 0.5),
              ),
            ),
            initialCountryCode: 'GH',
            onChanged: (phone) {
              onValueChanging(id, phone);
            },
          )
        : TextField(
            onChanged: (value) {
              id == "amount"
                  ? onValueChanging(id, '${selectedCurrency!.code} $value')
                  : onValueChanging(id, controller.text);
            },
            keyboardType: isAmount ? TextInputType.number : TextInputType.text,
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: isAmount
                  ? SizedBox(
                      width: 20,
                      child: GestureDetector(
                        onTap: () {
                          showCurrencyPicker(
                            context: context,
                            showFlag: true,
                            showCurrencyName: false,
                            showCurrencyCode: true,
                            onSelect: (Currency currency) {
                              setState(() {
                                selectedCurrency = currency;
                              });
                            },
                          );
                        },
                        child: Center(
                          child: Text(
                            selectedCurrency?.symbol ?? '₵',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
              labelText: label,
              labelStyle: AppStyles.header.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(200),
                borderSide: BorderSide(color: AppTheme.lightGrey, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(200),
                borderSide: BorderSide(color: AppTheme.lightGrey, width: 0.5),
              ),
            ),
          );
  }
}
