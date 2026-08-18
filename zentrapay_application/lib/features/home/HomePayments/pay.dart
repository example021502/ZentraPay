import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/repositories/payments_service.dart';
import 'package:zentrapay_application/core/repositories/search_repository.dart';
import 'package:zentrapay_application/core/repositories/transactions_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/AppConfirmSheet.dart';
import 'package:zentrapay_application/core/utils/Common/EnterAmount.dart';
import 'package:zentrapay_application/core/utils/Common/GenerateTransactionId.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/pay_search_section.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/recent_payments_list.dart';
import 'package:zentrapay_application/features/home/getCurrencyISOCodeHelper.dart';

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
  bool _payInFlight = false;

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
    TransactionsRepository.instance.ensureLoaded().catchError((_) {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Runs the full pay-a-contact flow: amount entry -> PIN confirmation ->
  /// POST /api/payments in the {TransactionId, pin, recipient, destination,
  /// transfer} shape the backend's PaymentRequestDTO expects.
  Future<void> _payUser(SearchAppUser recipient) async {
    if (_payInFlight) return;

    final sender = _searchResult.senderDetails;

    // Which of the recipient's currency accounts the money lands in: the
    // one matching the sender's own currency (search-contacts already
    // scopes appUsers to the sender's own country, so this is a same-
    // country wallet-to-wallet move — it can only land in a currency the
    // sender actually holds), falling back to the recipient's default
    // account if there's no exact match.
    AccountZentagOption? destination;
    if (recipient.fiatAccounts.isNotEmpty) {
      final currencyMatch = recipient.fiatAccounts
          .where((a) => a.currencyCode == sender.currency)
          .toList();
      destination = currencyMatch.isNotEmpty
          ? currencyMatch.first
          : recipient.defaultAccount;
    }

    if (destination == null) {
      ZentraNotifier.error(
        "Can't Send",
        "${recipient.fullName} doesn't have an account associate with that currency yet, change currency and try again.",
      );
      return;
    }
    // Local non-nullable binding: `destination` itself stays a captured,
    // reassignable variable, which the analyzer won't promote across the
    // closures below even after the null check above.
    final AccountZentagOption resolvedDestination = destination;

    final amountResult = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => EnterAmount(
        recipient: recipient.fullName,
        fixedCurrencyCode: resolvedDestination.currencyCode,
        fixedCurrencyFlag: extractCountryIsoCode(
          resolvedDestination.currencyCode,
        ),
      ),
    );
    if (amountResult == null || !mounted) return;

    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AppConfirmPinSheet(
        name: recipient.fullName,
        currencyCode: amountResult['currencyCode'],
        amount: amountResult['amount'],
        destination: resolvedDestination.zentag,
      ),
    );
    if (pin == null || pin.isEmpty || !mounted) return;

    final txnRef = generateTxnRef();

    // Payload must match the backend's PaymentRequestDTO exactly:
    // {TransactionId, pin,
    //  recipient:{fullName,email,phoneNumber,userType},
    //  destination:{countryCode,currencyCode,accountIdentifier,sourceType,
    //               sourceName,sourceIdentifier},
    //  transfer:{referenceId,amount,currencyCode,currencyType,purpose}}.
    // sourceType "zentrapay-wallet" routes it through the internal
    // wallet-to-wallet branch of PaymentsService.sendMoney.
    final amount =
        double.tryParse(amountResult['amount'].toString()) ?? 0;
    final payload = {
      "TransactionId": txnRef,
      "pin": pin,
      "recipient": {
        "fullName": recipient.fullName,
        "email": recipient.email,
        "phoneNumber": recipient.phoneNumber,
        "userType": recipient.userType.isNotEmpty ? recipient.userType : 'app-user',
      },
      "destination": {
        "countryCode": recipient.countryCode,
        "currencyCode": resolvedDestination.currencyCode,
        "accountIdentifier": resolvedDestination.zentag,
        "sourceType": "zentrapay-wallet",
        "sourceName": recipient.fullName,
        "sourceIdentifier": resolvedDestination.accountId,
      },
      "transfer": {
        "referenceId": txnRef,
        "amount": amount,
        "currencyCode": resolvedDestination.currencyCode,
        "currencyType": "fiat",
        "purpose": "",
      },
    };

    setState(() => _payInFlight = true);
    try {
      await PaymentsService.payment(payload: payload);
      if (!mounted) return;
      ZentraNotifier.success(
        "Payment Sent",
        "${amountResult['currencyCode']} ${amountResult['amount']} sent to ${recipient.fullName}.",
      );
    } catch (e) {
      if (!mounted) return;
      ZentraNotifier.error("Payment Failed", _extractErrorMessage(e));
    } finally {
      if (mounted) setState(() => _payInFlight = false);
    }
  }

  String _extractErrorMessage(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final data = e.response!.data as Map;
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'];
      }
    }
    return "Something went wrong. Please try again.";
  }

  /// Recent Payments only carries the counterparty's name/identifier (a
  /// zentag), not their full searchable profile — re-search for them so the
  /// same flow (with a live, current-balance account list) can run again.
  Future<void> _payRecentTransaction(AppTransaction transaction) async {
    final identifier = transaction.counterpartyIdentifier;
    if (identifier == null || identifier.isEmpty) {
      ZentraNotifier.error(
        "Can't Send",
        "Could not find this contact anymore.",
      );
      return;
    }
    try {
      final result = await SearchRepository.search(identifier);
      final match = result.appUsers.where(
        (u) => u.fiatAccounts.any((a) => a.zentag == identifier),
      );
      if (match.isEmpty || !mounted) {
        if (mounted) {
          ZentraNotifier.error(
            "Can't Send",
            "Could not find this contact anymore.",
          );
        }
        return;
      }
      await _payUser(match.first);
    } catch (e) {
      if (!mounted) return;
      ZentraNotifier.error(
        "Can't Send",
        "Could not find this contact anymore.",
      );
    }
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
                            if (_payInFlight) ...[
                              const SizedBox(width: AppTheme.spacingSm),
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        PaySearchSection(
                          controller: _searchController,
                          isSearching: isSearching,
                          searchResult: _searchResult,
                          onChanged: _onSearchChanged,
                          onSelectUser: _payUser,
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
                    onSelectTransaction: _payRecentTransaction,
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
