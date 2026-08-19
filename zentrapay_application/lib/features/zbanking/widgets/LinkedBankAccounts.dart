import 'package:flutter/cupertino.dart';

class LinkedBankAccounts extends StatefulWidget {
  final Map<String, dynamic> accounts;

  const LinkedBankAccounts({super.key, required this.accounts});

  @override
  State<LinkedBankAccounts> createState() => _LinkedBankAccountsState();
}

class _LinkedBankAccountsState extends State<LinkedBankAccounts> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 250,
        maxWidth: MediaQuery.of(context).size.width,
      ),
      child: const Placeholder(),
    );
  }
}
