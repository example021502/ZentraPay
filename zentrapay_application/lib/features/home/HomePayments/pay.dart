import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/repositories/payments_service.dart';
import 'package:zentrapay_application/core/repositories/search_repository.dart';
import 'package:zentrapay_application/core/repositories/transactions_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/AppConfirmSheet.dart';
import 'package:zentrapay_application/core/utils/Common/EnterAmount.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/pay_search_section.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/recent_payments_list.dart';

import '../../../core/utils/Common/GenerateTransactionId.dart';

class PaySectionMain extends StatefulWidget {
  const PaySectionMain({super.key});

  @override
  State<PaySectionMain> createState() => _PaySectionMainState();
}

class _PaySectionMainState extends State<PaySectionMain> {
  final TextEditingController _searchController = TextEditingController();
  ContactSearchResult _searchResult = ContactSearchResult.empty();
  bool isSearching = false;
  Timer? _debounceTimer;

  List<AppTransaction> get _recentPayments => TransactionsRepository
      .instance
      .items
      .where((t) => (t.counterpartyName ?? '').isNotEmpty)
      .take(10)
      .toList();

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResult = ContactSearchResult.empty();
        isSearching = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() => isSearching = true);
      try {
        final result = await SearchRepository.search(query);
        if (!mounted) return;
        setState(() => _searchResult = result);
      } catch (e) {
        debugPrint("Search API Error: $e");
      } finally {
        if (mounted) setState(() => isSearching = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    TransactionsRepository.instance.ensureLoaded();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _startPaymentFlow(Map<String, dynamic> recipientDetails) async {
    final amount = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => EnterAmount(
        recipient:
            recipientDetails["fullName"] ??
            "${recipientDetails["firstName"]} ${recipientDetails["lastName"]}",
      ),
    );
    if (amount == null || !mounted) return;

    if (!mounted) return;

    final String pin = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => AppConfirmPinSheet(
        name:
            recipientDetails['fullName'] ??
            "${recipientDetails['firstName']} ${recipientDetails['lastName']}",
        currencyCode: amount['currencyCode'],
        amount: amount['amount'],
      ),
    );

    final txnRef = generateTxnRef();
    print("THE TXN_REF IS:: $txnRef");

    final sender = _searchResult.senderDetails;
    final userType = recipientDetails['userType'];
    final isAppUser = userType == "app-user";
    final isFundingSource = userType == "funding-source";
    final isBillProvider = userType == "bill-provider";

    final isCrossBorder =
        sender.countryCode.toLowerCase() ==
        recipientDetails["countryCode"].toString().toLowerCase();

    final payload = {
      "TXN_REF": txnRef,
      "pin": pin,
      "isCrossBorder": isCrossBorder,
      "senderDetails": {
        "sender_id": sender.userId,
        "name": "${sender.firstName} ${sender.lastName}",
        "email": sender.email,
        "phone_number": sender.phoneNumber,
        "country_code": sender.countryCode,
        "user_type": sender.userType,
        "zentag": sender.zentag,
        "source_type": "WALLET",
      },
      "recipient": {
        "recipientId": recipientDetails['recipientId'],
        "recipientName": isAppUser
            ? "${recipientDetails["firstName"]} ${recipientDetails["lastName"]}"
            : isFundingSource
            ? recipientDetails["accountName"]
            : isBillProvider
            ? recipientDetails["providerName"]
            : "Unknown",
        "identifier": isAppUser
            ? recipientDetails["zentag"]
            : isFundingSource
            ? recipientDetails["accountIdentifier"]
            : isBillProvider
            ? recipientDetails["billerCode"]
            : "Unknown",
        "type": recipientDetails['userType'],
      },
      "amountDetails": {
        "currency_code": amount['currencyCode'],
        "tax": 0.00,
        "fee": 0.00,
        "discount": 0.00,
        "total_amount": amount['amount'],
      },
    };

    final response = await PaymentsService.payment(payload: payload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryWhite,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 100,
        child: FloatingActionButton(
          onPressed: () {},
          elevation: 0,
          backgroundColor: AppTheme.primaryWhite,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.primaryWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: const Icon(
                  Icons.qr_code_2_outlined,
                  color: AppTheme.primaryPink,
                  size: 35,
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  "Scan",
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryPink,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: TransactionsRepository.instance,
          builder: (context, _) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingMd,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(
                                Icons.arrow_back,
                                size: 22,
                                color: AppTheme.textBlack,
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Text("Send Money", style: AppTheme.headlineSmall),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        PaySearchSection(
                          controller: _searchController,
                          isSearching: isSearching,
                          searchResult: _searchResult,
                          onChanged: _onSearchChanged,
                          onSelectUser: (user) =>
                              _startPaymentFlow(user as Map<String, dynamic>),
                          onSelectBillProvider: (_) => ZentraNotifier.error(
                            "Not Supported",
                            "Paying bill providers from here is not yet supported.",
                          ),
                          onSelectFundingSource: (_) => ZentraNotifier.error(
                            "Not Supported",
                            "Sending to this recipient type is not yet supported.",
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                    ),
                    child: Text("Recent Payments", style: AppTheme.labelLarge),
                  ),
                  RecentPaymentsList(
                    recentPayments: _recentPayments,
                    onSelectTransaction: (transaction) {
                      final displayName =
                          transaction.counterpartyName ?? "Unknown";
                      final identifier = transaction.counterpartyIdentifier;
                      final isZentag = identifier?.contains('@') ?? false;

                      _startPaymentFlow(transaction as Map<String, dynamic>);
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
