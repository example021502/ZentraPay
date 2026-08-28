import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/repositories/search_repository.dart';
import 'package:zentrapay_application/core/repositories/transactions_repository.dart';
import 'package:zentrapay_application/core/repositories/wallets_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/makePayment.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/pay_search_section.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/recent_payments_list.dart';

class PaySectionMain extends StatefulWidget {
  const PaySectionMain({super.key});

  @override
  State<PaySectionMain> createState() => _PaySectionMainState();
}

class _PaySectionMainState extends State<PaySectionMain> {
  final TextEditingController _searchController = TextEditingController();
  ContactSearchResult _searchResult = ContactSearchResult.empty();
  PaymentController makePayment = PaymentController();
  bool isSearching = false;
  Timer? _debounceTimer;
  bool _payInFlight = false;

  /// Recent Payments is a *response* strip, not a raw transaction log —
  /// collapse repeated payments to the same counterparty into a single tile
  /// so a response never appears twice, keeping each response's most recent
  /// transaction (items are newest-first).
  List<AppTransaction> get _recentPayments {
    final unique = <String, AppTransaction>{};
    for (final transaction in TransactionsRepository.instance.items) {
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

  @override
  void initState() {
    super.initState();
    TransactionsRepository.instance.ensureLoaded().catchError((_) {});
    // The pay flow now derives the destination currency from the sender's
    // own fiat accounts, so make sure wallet balances are loaded up-front.
    WalletsRepository.instance.ensureLoaded().catchError((_) => null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// backend DTOs were simplified), so the recipient's destination account is
  /// no longer picked from their searched accounts. Instead we drive the
  /// transfer currency from the *sender's own* fiat accounts and let the
  /// backend resolve the recipient's wallet by email/phone in the currency
  /// of the transfer.

  /// Recent Payments only carries the counterparty's name/identifier, not
  /// their full searchable profile — try to re-search them so the same flow
  /// (with a live, verified profile) can run again. If the search comes back
  /// empty or fails, fall back to a recipient built from the transaction
  /// itself so tapping a response ALWAYS starts the payment flow (Enter
  /// Amount -> PIN confirmation) instead of dead-ending with an error.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryWhite,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 100,
        child: FloatingActionButton(
          onPressed: () {
            showComingSoon(context, "scanning qr code");
          },
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
                          onSelectUser: (SearchAppUser user) async {
                            Map<String, dynamic> recipient = {
                              "fullName": user.fullName,
                              "email": user.email,
                              "phoneNumber": user.phoneNumber,
                              "countryCode": user.countryCode,
                            };
                            final String? zentrapayId =
                                dotenv.env["zentrapay_id"];
                            Map<String, dynamic> destination = {
                              "accountIdentifier": user.phoneNumber,
                              "destinationSourceType": "zentrapay-wallet",
                              "destinationSourceName": "zentrapay",
                              "destinationSourceCode": zentrapayId,
                              "countryCode": user.countryCode,
                            };
                            await makePayment.processPayment(
                              context: context,
                              recipientNameForUI: user.fullName,
                              recipientMap: recipient,
                              destinationMap: destination,
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
                          onSelectBank: (_) =>
                              showComingSoon(context, "Sending to bank"),
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
                    onSelectTransaction: (AppTransaction transaction) async {
                      if (_payInFlight) return;

                      // Try to re-resolve the counterparty's live profile so
                      // we send to their current email/phone. If the search
                      // fails, comes back empty, or isn't an app user, fall
                      // back to the identifiers stored on the transaction so
                      // tapping ALWAYS starts the payment flow (Enter Amount
                      // -> PIN confirmation) instead of dead-ending.
                      final String identifier = transaction.receiverId.trim();
                      if (identifier.isNotEmpty) {
                        try {
                          final response = await SearchRepository.targetSearch(
                            identifier,
                          );

                          if (response.isNotEmpty &&
                              response['userType'] == 'app-user') {
                            final String fullName =
                                "${response['firstName']} ${response['lastName']}";
                            Map<String, dynamic> recipient = {
                              "fullName": fullName,
                              "email": response['email'],
                              "phoneNumber": response['phoneNumber'],
                              "countryCode": response['countryCode'],
                            };
                            final String? zentrapayId =
                                dotenv.env["zentrapay_id"];
                            Map<String, dynamic> destination = {
                              "accountIdentifier": response['phoneNumber'],
                              "destinationSourceType": "zentrapay-wallet",
                              "destinationSourceName": "zentrapay",
                              "destinationSourceCode": zentrapayId,
                              "countryCode": response['countryCode'],
                            };
                            if (!mounted) return;
                            await makePayment.processPayment(
                              context: context,
                              recipientNameForUI: fullName,
                              recipientMap: recipient,
                              destinationMap: destination,
                              onStateChanged: (bool newInFlight) {
                                setState(() {
                                  _payInFlight = newInFlight;
                                });
                              },
                            );
                          }
                        } catch (e) {
                          debugPrint(
                            "Recent-contact re-search failed, using stored "
                            "details: $e",
                          );
                        }
                      }
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
