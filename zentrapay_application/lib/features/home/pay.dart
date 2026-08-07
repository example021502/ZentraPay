import 'dart:async'; // Required for Timer (Debouncing)

import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/repositories/search_repository.dart';
import 'package:zentrapay_application/core/repositories/transactions_repository.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/AppPinSheet.dart';
import 'package:zentrapay_application/core/utils/Common/EnterAmount.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';

class PaySectionMain extends StatefulWidget {
  const PaySectionMain({super.key});

  @override
  State<PaySectionMain> createState() => _PaySectionMainState();
}

class _PaySectionMainState extends State<PaySectionMain> {
  final TextEditingController _searchController = TextEditingController();

  // Search state tracking variables
  ContactSearchResult _searchResult = ContactSearchResult.empty();
  bool isSearching = false;
  Timer? _debounceTimer;

  /// Recent payments shown here are simply the most-recent transactions that
  /// went to a named counterparty — there is no dedicated "recent contacts"
  /// endpoint, so this reuses the shared TransactionsRepository cache.
  List<AppTransaction> get _recentPayments => TransactionsRepository
      .instance
      .items
      .where((t) => (t.counterpartyName ?? '').isNotEmpty)
      .take(10)
      .toList();

  // Professional Debouncer implementation
  void _onSearchChanged(String query) {
    // Cancel the previous timer if the user types another character within 500ms
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResult = ContactSearchResult.empty();
        isSearching = false;
      });
      return;
    }

    // Set a delay of 500ms before sending the network request
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      setState(() {
        isSearching = true;
      });

      try {
        final result = await SearchRepository.search(query);
        if (!mounted) return;
        setState(() {
          _searchResult = result;
        });
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
    _debounceTimer?.cancel(); // Always cancel timers to avoid memory leaks
    super.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  textAlign: TextAlign.center,
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
            final recentPayments = _recentPayments;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Search Section Wrapper
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMd,
                      vertical: AppTheme.spacingMd,
                    ),
                    child: Column(
                      spacing: AppTheme.spacingSm,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          spacing: AppTheme.spacingSm,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Icon(
                                Icons.arrow_back,
                                size: 22,
                                color: AppTheme.textBlack,
                              ),
                            ),

                            Text("Send Money", style: AppTheme.headlineSmall),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingLg),
                        SearchBar(
                          controller: _searchController,
                          hintText: "Search @zentag, phone, bank ac. no. etc",
                          hintStyle: WidgetStateProperty.all(
                            TextStyle(color: AppTheme.gray500, fontSize: 14),
                          ),
                          leading: const Icon(
                            Icons.search,
                            color: AppTheme.gray500,
                          ),
                          trailing: [
                            if (isSearching)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.primaryPink,
                                  ),
                                ),
                              ),
                          ],
                          elevation: WidgetStateProperty.all(0),
                          backgroundColor: WidgetStateProperty.all(
                            AppTheme.gray100,
                          ),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(horizontal: 15.0),
                          ),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull,
                              ),
                            ),
                          ),
                          onChanged: _onSearchChanged, // Trigger debouncer here
                        ),

                        // Dynamic Fit and Scrollable Search Matches Box Layout
                        if (_searchController.text.isNotEmpty)
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 250, // Hard ceiling cap rule context
                            ),
                            child: _hasSearchResults
                                ? SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ..._searchResult.appUsers.map(
                                          (u) => _buildSearchedAppUser(u),
                                        ),
                                        ..._searchResult.billProviders.map(
                                          (b) => _buildSearchedBillProvider(b),
                                        ),
                                        ..._searchResult.fundingSources.map(
                                          (f) => _buildSearchedFundingSource(f),
                                        ),
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                      ),
                                      child: Text(
                                        isSearching
                                            ? "Searching system records..."
                                            : "No matches found",
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.gray500,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),

                  // 2. Recent Payments Header Row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Recent Payments", style: AppTheme.labelLarge),
                      ],
                    ),
                  ),

                  // 3. Horizontal Recents ListView Row
                  SizedBox(
                    height: 95,
                    child: recentPayments.isNotEmpty
                        ? ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.only(
                              left: 16.0,
                              right: 8.0,
                            ),
                            itemCount: recentPayments.length,
                            itemBuilder: (context, index) {
                              return _buildRecentContactItem(
                                recentPayments[index],
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              "No recent contacts",
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.gray500,
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: AppTheme.spacingLg),

                  // 4. Billers Section — the unified bill-providers catalog
                  // is a directory of billers, not a per-user outstanding
                  // bill list, so there's no real "your bills" data to show
                  // here yet; the New/More menu (Quick Actions) is where a
                  // user browses and pays a biller.
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool get _hasSearchResults =>
      _searchResult.appUsers.isNotEmpty ||
      _searchResult.billProviders.isNotEmpty ||
      _searchResult.fundingSources.isNotEmpty;

  // searched app users — the only recipient type with a real payment path.
  Widget _buildSearchedAppUser(SearchAppUser user) {
    final recipientDetails = Map<String, dynamic>.from(
      user as Map<dynamic, dynamic>,
    );
    print("THE RECIPIENT DETAILS ARE:: $recipientDetails");
    return _searchResultTile(
      title: user.zentag,
      subtitle: user.fullName,
      dimmed: false,
      onTap: () => _startPaymentFlow(recipientDetails),
    );
  }

  // Searched bill providers — dimmed since there's no live pay-a-biller
  // endpoint wired into this sheet yet (that lives behind Quick Actions'
  // "New Bill Provider" picker instead).
  Widget _buildSearchedBillProvider(SearchBillProvider provider) {
    return _searchResultTile(
      title: provider.billerName,
      subtitle: "${provider.categoryCode} · Coming soon",
      dimmed: true,
      onTap: () => ZentraNotifier.error(
        "Not Supported",
        "Paying bill providers from here is not yet supported.",
      ),
    );
  }

  Widget _buildSearchedFundingSource(SearchFundingSource source) {
    return _searchResultTile(
      title: source.sourceName,
      subtitle: "${source.accountIdentifier} · Coming soon",
      dimmed: true,
      onTap: () => ZentraNotifier.error(
        "Not Supported",
        "Sending to this recipient type is not yet supported.",
      ),
    );
  }

  Widget _searchResultTile({
    required String title,
    required String subtitle,
    required bool dimmed,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        onTap: onTap,
        child: Opacity(
          opacity: dimmed ? 0.55 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.spacingLg),
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.spacingSm,
              horizontal: AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: AppTheme.gray100,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.secondaryNavy.withValues(
                      alpha: 0.1,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 30,
                      color: AppTheme.secondaryNavy,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    flex: 0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTheme.labelLarge,
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Recent payments contacts ========================
  Widget _buildRecentContactItem(AppTransaction transaction) {
    final displayName = transaction.counterpartyName ?? "Unknown";
    // Zentags in this app are shaped like "<phone>@zentrapay" — use that to
    // tell apart a zentag identifier from a bare phone number, since the
    // transaction record itself doesn't tag which one counterpartyIdentifier
    // is.
    final identifier = transaction.counterpartyIdentifier;
    final isZentag = identifier?.contains('@') ?? false;

    final paymentForm = {
      "amount": "",
      "currency_code": "",
      "name": displayName,
      "recipientType": "app-user",
      if (isZentag) "zentag": identifier,
      if (!isZentag) "phoneNumber": identifier,
    };

    return GestureDetector(
      onTap: () => _startPaymentFlow(paymentForm),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.secondaryNavy.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                size: 30,
                color: AppTheme.secondaryNavy,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 0,
              child: Text(
                displayName,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: AppTheme.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startPaymentFlow(Map<String, dynamic> recipientDetails) async {
    final amount = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) =>
          EnterAmount(recipient: recipientDetails["fullName"] ?? "Unknown"),
    );
    if (amount == null || !mounted) return;
    final amountDetails = {
      "amount": amount['amount'],
      "currencyCode": amount['currency_code'],
    };

    if (!mounted) return;

    // confirm PIN
    final pin = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) =>
          AppPinSheet.confirmTransaction(form: recipientDetails),
    );

    final paymentForm = {
      "recipientDetails": recipientDetails,
      "pin": pin,
      "amountDetails": amountDetails,
    };

    // final transaction = await
  }
}
