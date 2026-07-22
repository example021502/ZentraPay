import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:zentrapay_application/main.dart';

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

  Map<String, String> formData = {
    "recipient_name": "",
    "amount": "",
    "payout_option": "",
    "contact_number": "",
    "country": "",
    "account_number": "",
  };

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

  @override
  void dispose() {
    // Clean up all individual text field controllers
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
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    spacing: 10,
                    children: [
                      Text(
                        "Send Now",
                        style: AppStyles.header.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Icon(Icons.send, color: AppColors.primary, size: 20),
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
        _textField(
          label: "Recipient Full name",
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
          label: "Bank Ac. No. / IBAN ",
          controller: _bankController,
          isPhoneField: false,
          isAmount: false,
          id: "account_number",
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
              fillColor: AppColors.primary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(200),
                borderSide: BorderSide(color: AppColors.lightGrey, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(200),
                borderSide: BorderSide(color: AppColors.lightGrey, width: 0.5),
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
                borderSide: BorderSide(color: AppColors.lightGrey, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(200),
                borderSide: BorderSide(color: AppColors.lightGrey, width: 0.5),
              ),
            ),
          );
  }
}
