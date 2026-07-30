import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class ReceiverForm extends StatefulWidget {
  final String payoutOption;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController accountNumberController;
  final TextEditingController phoneNumberController;
  final String? selectedBankId;
  final String? selectedMomoProviderCode;
  final List<Map<String, String>> supportedBanks;
  final List<Map<String, String>> supportedMomoNetworks;
  final ValueChanged<String> onPayoutOptionChanged;
  final ValueChanged<String?> onBankChanged;
  final ValueChanged<String?> onMomoChanged;

  const ReceiverForm({
    super.key,
    required this.payoutOption,
    required this.firstNameController,
    required this.lastNameController,
    required this.accountNumberController,
    required this.phoneNumberController,
    this.selectedBankId,
    this.selectedMomoProviderCode,
    required this.supportedBanks,
    required this.supportedMomoNetworks,
    required this.onPayoutOptionChanged,
    required this.onBankChanged,
    required this.onMomoChanged,
  });

  @override
  State<ReceiverForm> createState() => _ReceiverFormState();
}

class _ReceiverFormState extends State<ReceiverForm> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Receiver Information",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.lightGrey.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Payout Destination Type",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onPayoutOptionChanged('bank'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.payoutOption == 'bank'
                              ? AppColors.secondary
                              : Colors.grey.shade200,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Bank Account",
                          style: TextStyle(
                            color: widget.payoutOption == 'bank'
                                ? AppColors.primary
                                : AppColors.textBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => widget.onPayoutOptionChanged('momo'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: widget.payoutOption == 'momo'
                              ? AppColors.secondary
                              : Colors.grey.shade200,
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Mobile Money",
                          style: TextStyle(
                            color: widget.payoutOption == 'momo'
                                ? AppColors.primary
                                : AppColors.textBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: widget.firstNameController,
                      decoration: const InputDecoration(
                        labelText: "Receiver First Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: widget.lastNameController,
                      decoration: const InputDecoration(
                        labelText: "Receiver Last Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.payoutOption == 'bank') ...[
                DropdownButtonFormField<String>(
                  value: widget.selectedBankId,
                  hint: const Text("Select Supported Bank"),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  items: widget.supportedBanks.map((bank) {
                    return DropdownMenuItem<String>(
                      value: bank["id"],
                      child: Text(bank["name"]!),
                    );
                  }).toList(),
                  onChanged: widget.onBankChanged,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: widget.accountNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Account Number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: widget.selectedMomoProviderCode,
                  hint: const Text("Select Mobile Money Network"),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  items: widget.supportedMomoNetworks.map((momo) {
                    return DropdownMenuItem<String>(
                      value: momo["code"],
                      child: Text(momo["name"]!),
                    );
                  }).toList(),
                  onChanged: widget.onMomoChanged,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: widget.phoneNumberController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Mobile Number",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
