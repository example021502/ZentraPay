import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';

import 'PinConfirmationBottomSheet.dart';
import 'receiver_form.dart';
import 'recent_remittances.dart';
import 'remittance_api_services.dart';
import 'transfer_calculator.dart';
import 'zremit_header.dart';

class ZRemitScreen extends StatefulWidget {
  const ZRemitScreen({super.key});

  @override
  State<ZRemitScreen> createState() => _ZRemitScreenState();
}

class _ZRemitScreenState extends State<ZRemitScreen> {
  final TextEditingController _amountController = TextEditingController(
    text: '0.00',
  );
  String _selectedSourceCurrency = 'USD';
  String _selectedTargetCurrency = 'GHS';
  final double _exchangeRate = 15.45;
  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'GHS', 'NGN', 'KES'];
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  String? _selectedBankId;
  String? _selectedMomoProviderCode;
  String _payoutOption = 'bank';

  final List<Map<String, String>> _supportedBanks = [
    {"id": "BANK_GCB_GH", "name": "GCB Bank PLC (Ghana)", "currency": "GHS"},
    {
      "id": "BANK_STANCH_GH",
      "name": "Standard Chartered Bank (Ghana)",
      "currency": "GHS",
    },
    {
      "id": "BANK_ZENITH_NG",
      "name": "Zenith Bank PLC (Nigeria)",
      "currency": "NGN",
    },
    {
      "id": "BANK_GLOBUS_NG",
      "name": "Globus Bank (Nigeria)",
      "currency": "NGN",
    },
  ];

  final List<Map<String, String>> _supportedMomoNetworks = [
    {
      "code": "MOMO_MTN_GH",
      "name": "MTN Mobile Money (Ghana)",
      "currency": "GHS",
    },
    {"code": "MOMO_VOD_GH", "name": "Vodafone Cash (Ghana)", "currency": "GHS"},
    {
      "code": "MOMO_MTN_NG",
      "name": "MTN MoMo PSB (Nigeria)",
      "currency": "NGN",
    },
    {
      "code": "MOMO_AIRTEL_KE",
      "name": "Airtel Money (Kenya)",
      "currency": "KES",
    },
  ];

  final List<Map<String, dynamic>> _recentRemittances = [
    {
      "recipient": "Kwame Mensah",
      "corridor": "USD -> GHS",
      "amount": "GHS 7,725.00",
      "date": "Today, 11:30 AM",
      "status": "Completed",
      "avatar": Icons.person,
    },
    {
      "recipient": "Amina Bello",
      "corridor": "USD -> NGN",
      "amount": "NGN 750,000.00",
      "date": "Yesterday",
      "status": "Processing",
      "avatar": Icons.person,
    },
  ];

  Map<String, dynamic> _saveDataToMaps() {
    final currencyDetails = {
      "sourceAmount": _amountController.text,
      "sourceCurrencyCode": _selectedSourceCurrency,
      "destinationAmount": "",
      "destinationCurrencyCode": _selectedTargetCurrency,
      "payoutOption": _payoutOption,
    };
    final recipientDetails = {
      "receiverFirstname": _firstNameController.text,
      "receiverLastName": _lastNameController.text,
    };
    final bankDetails = {
      "bankId": _selectedBankId ?? "",
      "accountNumber": _accountNumberController.text,
    };
    final mobileMoneyDetails = {
      "mobileNetworkCode": _selectedMomoProviderCode ?? "",
      "phoneNumber": _phoneNumberController.text,
    };

    return {
      "currencyDetails": currencyDetails,
      "recipientDetails": recipientDetails,
      "bankDetails": bankDetails,
      "mobileMoneyDetails": mobileMoneyDetails,
    };
  }

  bool isFormFilled() {
    if (_amountController.text == "" ||
        _firstNameController.text == "" ||
        _lastNameController.text == "" ||
        (_accountNumberController.text == "" &&
            _phoneNumberController.text == "")) {
      return false;
    }
    return true;
  }

  void _clearForm() {
    _amountController.text = '0.00';
    _selectedSourceCurrency = 'USD';
    _selectedTargetCurrency = 'GHS';
    _firstNameController.clear();
    _lastNameController.clear();
    _selectedBankId = null;
    _selectedMomoProviderCode = null;
    _accountNumberController.clear();
    _phoneNumberController.clear();
    _payoutOption = 'bank';
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZRemitHeader(title: "ZRemit"),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TransferCalculator(
                    amountController: _amountController,
                    selectedSourceCurrency: _selectedSourceCurrency,
                    selectedTargetCurrency: _selectedTargetCurrency,
                    exchangeRate: _exchangeRate,
                    currencies: _currencies,
                    onSourceCurrencyChanged: (value) =>
                        setState(() => _selectedSourceCurrency = value),
                    onTargetCurrencyChanged: (value) =>
                        setState(() => _selectedTargetCurrency = value),
                  ),
                  const SizedBox(height: 25),
                  ReceiverForm(
                    payoutOption: _payoutOption,
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    accountNumberController: _accountNumberController,
                    phoneNumberController: _phoneNumberController,
                    selectedBankId: _selectedBankId,
                    selectedMomoProviderCode: _selectedMomoProviderCode,
                    supportedBanks: _supportedBanks,
                    supportedMomoNetworks: _supportedMomoNetworks,
                    onPayoutOptionChanged: (value) =>
                        setState(() => _payoutOption = value),
                    onBankChanged: (value) =>
                        setState(() => _selectedBankId = value),
                    onMomoChanged: (value) =>
                        setState(() => _selectedMomoProviderCode = value),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!isFormFilled()) {
                          ZentraNotifier.error(
                            "Missing Fields",
                            "All fields are required",
                          );
                          return;
                        }
                        final data = _saveDataToMaps();
                        final String? pin = await showTransferPinBottomSheet(
                          context,
                        );
                        if (pin != null && pin.length == 4) {
                          try {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                            final response = await submitRemittanceTransfer(
                              currencyDetails: data["currencyDetails"]!,
                              recipientDetails: data["recipientDetails"]!,
                              payoutType: _payoutOption,
                              bankDetails: data["bankDetails"]!,
                              mobileMoneyDetails: data["mobileMoneyDetails"]!,
                              transactionPin: pin,
                            );
                            if (mounted) Navigator.pop(context);
                            ZentraNotifier.success(
                              "Success",
                              "Transfer initiated! ID: ${response['transactionId'] ?? 'N/A'}",
                            );
                            _clearForm();
                          } catch (e) {
                            if (mounted && Navigator.canPop(context))
                              Navigator.pop(context);
                            ZentraNotifier.error(
                              "Transfer Failed",
                              "Something went wrong. Please try again.",
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Continue Transfer",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  RecentRemittances(remittances: _recentRemittances),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> showTransferPinBottomSheet(BuildContext context) async {
  return await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const PinConfirmationBottomSheet(),
  );
}
