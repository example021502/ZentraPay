import 'package:flutter/material.dart';

class MobileMoneyForm extends StatelessWidget {
  final String? selectedMomoProviderCode;
  final TextEditingController phoneNumberController;
  final List<Map<String, String>> supportedMomoNetworks;
  final ValueChanged<String?> onMomoChanged;

  const MobileMoneyForm({
    super.key,
    required this.selectedMomoProviderCode,
    required this.phoneNumberController,
    required this.supportedMomoNetworks,
    required this.onMomoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: selectedMomoProviderCode,
          hint: const Text("Select Mobile Money Network"),
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          items: supportedMomoNetworks.map((momo) {
            return DropdownMenuItem<String>(
              value: momo["code"],
              child: Text(momo["name"]!),
            );
          }).toList(),
          onChanged: onMomoChanged,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneNumberController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: "Mobile Number",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
