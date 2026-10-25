import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/make_payment.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/pay_search_section.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/verify_payee_sheet.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/recent_payments_list.dart';
import 'package:zentrapay_application/features/home/HomePayments/qr_scan_screen.dart';
import 'package:zentrapay_application/features/home/HomePayments/send_again_flow.dart';

class PaySectionMain extends StatefulWidget {
  const PaySectionMain({super.key});

  @override
  State<PaySectionMain> createState() => _PaySectionMainState();
}

class _PaySectionMainState extends State<PaySectionMain> {
  bool isSearching = false;
  PaymentController makePayment = PaymentController();

  Timer? _debounceTimer;
  bool _payInFlight = false;
  final TextEditingController _searchController = TextEditingController();
  ContactSearchResult _searchResult = ContactSearchResult.empty();

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    TransactionsRepository.instance.ensureLoaded().catchError((_) {});
    // The pay flow now derives the destination currency from the sender's
    // own fiat accounts, so make sure wallet balances are loaded up-front.
    WalletsRepository.instance.ensureLoaded().catchError((_) => null);
  }

  /// Recent Payments is a *response* strip, not a raw transaction log —
  /// collapse repeated payments to the same counterparty into a single tile
  /// so a response never appears twice, keeping each response's most recent
  /// transaction (items are newest-first).
  ///
  /// Only outgoing rows qualify: an incoming row records the user themself
  /// as receiver (see [canSendAgain]), which is not a payable counterparty.
  List<AppTransaction> get _recentPayments {
    final unique = <String, AppTransaction>{};
    for (final transaction in TransactionsRepository.instance.items) {
      if (!canSendAgain(transaction)) continue;
      final id = transaction.receiverId.trim().toLowerCase();
      final name = transaction.receiverName.trim().toLowerCase();
      final key = (id.isNotEmpty)
          ? 'id:$id'
          : (name.isNotEmpty)
          ? 'name:$name'
          : 'txn:${transaction.transactionId}';
      unique.putIfAbsent(key, () => transaction);
    }
    return unique.values.take(5).toList();
  }

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

  /// Tapping a Recent Payments tile: raises the global loading overlay
  /// (top of the stack), runs the contact re-search while it's up, then
  /// hands off to the normal Enter Amount -> PIN flow. See
  /// [sendAgainFromTransaction] — it owns the in-flight latch for the whole
  /// run and always reports back, so `_payInFlight` can never stick on.
  Future<void> _onSelectRecentPayment(AppTransaction transaction) async {
    if (_payInFlight) return;
    await sendAgainFromTransaction(
      context: context,
      transaction: transaction,
      controller: makePayment,
      onStateChanged: (bool inFlight) {
        if (mounted) setState(() => _payInFlight = inFlight);
      },
    );
  }

  /// A bank or mobile-money network was picked: collect the account number,
  /// have the payment providers confirm who owns it, and only then go on to
  /// Enter Amount -> PIN -> POST /api/payments/initialize.
  Future<void> _onSelectExternal({
    Banks? bank,
    MobileMoneyProvider? mobileMoney,
  }) async {
    if (_payInFlight) return;
    final payee = await showVerifyPayeeSheet(
      context: context,
      bank: bank,
      mobileMoney: mobileMoney,
    );
    if (payee == null || !mounted) return;

    await makePayment.processPayment(
      context: context,
      recipientNameForUI: payee.displayName,
      recipientMap: payee.recipient,
      channelType: payee.kind == PayeeKind.bank ? "BANK" : "MOMO",
      onStateChanged: (bool newInFlight) {
        setState(() {
          _payInFlight = newInFlight;
        });
      },
    );
  }

  /// Scan the receiver's QR code, extract their details from the payload and
  /// jump straight into the shared payment flow (Enter Amount -> PIN ->
  /// POST /api/payments/initialize), exactly like selecting a searched
  /// contact does.
  Future<void> _onScanQr() async {
    if (_payInFlight) return;

    final ScannedPaymentTarget? target = await QrScanScreen.show(context);
    if (target == null || !mounted) return;

    await makePayment.processPayment(
      context: context,
      recipientNameForUI: target.recipient['name'] as String,
      recipientMap: target.recipient,
      channelType: "INTERNAL",
      // Preselect the currency the scanned QR account is denominated in so
      // the transfer lands in an account the receiver actually holds.
      preferredCurrencyCode: target.receiveCurrency,
      onStateChanged: (bool newInFlight) {
        setState(() {
          _payInFlight = newInFlight;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 100,
        child: FloatingActionButton(
          onPressed: _onScanQr,
          elevation: 0,
          backgroundColor: Colors.transparent,
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
                child: Icon(
                  Icons.qr_code_2_outlined,
                  color: AppTheme.textBlack,
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                Text(
                                  "Send Money",
                                  style: AppTheme.headlineSmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        PaySearchSection(
                          controller: _searchController,
                          isSearching: isSearching,
                          searchResult: _searchResult,
                          onChanged: _onSearchChanged,
                          onSelectUser: (SearchAppUser user) async {
                            Map<String, dynamic> recipient = {
                              "userId": user.userId,
                              "name": "${user.firstName} ${user.lastName}",
                              "zentag": user.zentag,
                              "accountNumber": "",
                              "phoneNumber": user.phoneNumber,
                              "countryCode": user.countryCode,
                              "type": user.userType,
                            };

                            // CONSTRUCTING THE DESTINATION ------ COMMNENTEND FOR NOW
                            // final String? zentrapayId =
                            //     dotenv.env["zentrapay_id"];
                            // Map<String, dynamic> destination = {
                            //   "accountIdentifier": user.phoneNumber,
                            //   "accountName":
                            //       "${user.firstName} ${user.lastName}",
                            //   "checkoutType": "zentrapay_app",
                            //   "channelCode": zentrapayId ?? "zentrapay_app",
                            //   "countryCode": user.countryCode,
                            // };

                            await makePayment.processPayment(
                              context: context,
                              recipientNameForUI:
                                  "${user.firstName} ${user.lastName}",
                              recipientMap: recipient,
                              channelType: "INTERNAL",
                              onStateChanged: (bool newInFlight) {
                                setState(() {
                                  _payInFlight = newInFlight;
                                });
                              },
                            );
                          },
                          onSelectBillProvider: (_) => showComingSoon(
                            context,
                            "Sending to a bill provider",
                          ),
                          onSelectBank: (bank) => _onSelectExternal(bank: bank),
                          onSelectMobileMoney: (momo) =>
                              _onSelectExternal(mobileMoney: momo),
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
                    onSelectTransaction: _onSelectRecentPayment,
                  ),

                  // FOR FUTURE:: FOR ACCESSING THE USER PHONE CONTACTS AND SHOWING THEM IN THE PAY SECTION
                  // const SizedBox(height: AppTheme.spacingLg),
                  // Padding(
                  //   padding: const EdgeInsets.all(15.0),
                  //   child: Column(
                  //     mainAxisAlignment: MainAxisAlignment.start,
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       Text("Other people", style: AppTheme.labelLarge),
                  //       const SizedBox(height: AppTheme.spacingSm),
                  //       Center(
                  //         child: Text(
                  //           "Nothing yet",
                  //           style: AppTheme.labelLarge.copyWith(
                  //             color: AppTheme.lightGrey,
                  //           ),
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
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
