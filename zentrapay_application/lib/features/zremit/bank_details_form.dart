import 'package:flutter/material.dart';

class BankDetailsForm extends StatelessWidget {
  final String? selectedBankId;
  final TextEditingController accountNumberController;
  final List<Map<String, String>> supportedBanks;
  final ValueChanged<String?> onBankChanged;

  const BankDetailsForm({
    super.key,
    required this.selectedBankId,
    required this.accountNumberController,
    required this.supportedBanks,
    required this.onBankChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedBankId,
          hint: const Text("Select Supported Bank"),
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          items: supportedBanks.map((bank) {
            return DropdownMenuItem<String>(
              value: bank["id"],
              child: Text(bank["name"]!),
            );
          }).toList(),
          onChanged: onBankChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: accountNumberController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Account Number",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
