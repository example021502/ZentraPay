import 'dart:async'; // 💡 Required for Timer (Debouncing)

import 'package:flutter/material.dart';
import 'package:zentrapay_application/Common/EnterAmount.dart';
import 'package:zentrapay_application/home_wallet/api_home_wallet_services.dart';
import "package:zentrapay_application/main.dart";

import '../../Common/EnterPIN.dart';

class PaySectionMain extends StatefulWidget {
  const PaySectionMain({super.key});

  @override
  State<PaySectionMain> createState() => _PaySectionMainState();
}

class _PaySectionMainState extends State<PaySectionMain> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> paymentsHistory = [];
  List<Map<String, dynamic>> bills = [];

  // 💡 Search state tracking variables
  List<Map<String, dynamic>> searchedContacts = [];
  bool isSearching = false;
  Timer? _debounceTimer;

  void _getRecentPayments_Bills() async {
    try {
      final payments = await getRecentPaymentsBills();
      debugPrint("The payments: $payments");
      if (!payments?["success"]) {
        return;
      }
      if (!mounted) return;
      setState(() {
        paymentsHistory = [...payments?['transactions']];
        bills = payments?["bills"] ?? [];
      });
    } catch (e) {
      debugPrint("Payment Error: $e");
    }
  }

  // 💡 Professional Debouncer implementation
  void _onSearchChanged(String query) {
    // Cancel the previous timer if the user types another character within 500ms
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        searchedContacts = [];
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
        final response = await searchContacts(query);
        print("The searched contacts are: $response");
        if (!response["success"]) {
          return;
        }

        setState(() {
          searchedContacts = List<Map<String, dynamic>>.from(
            response["result"] ?? [],
          );
          isSearching = false;
        });
      } catch (e) {
        debugPrint("Search API Error: $e");
        if (mounted) setState(() => isSearching = false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getRecentPayments_Bills();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel(); // 💡 Always cancel timers to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 100,
        child: FloatingActionButton(
          onPressed: () {},
          elevation: 0,

          backgroundColor: AppColors.primary,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(200),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textBlack.withAlpha(20),
                      offset: Offset(0, 0),
                      spreadRadius: 2.0,
                      blurRadius: 5.0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.qr_code_2_outlined,
                  color: AppColors.main,
                  size: 35,
                ),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: Text(
                  "Scan",
                  textAlign: TextAlign.center,
                  style: AppStyles.text.copyWith(
                    color: AppColors.main,
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Search Section Wrapper
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 15.0,
                ),
                child: Column(
                  spacing: 10,
                  children: [
                    SearchBar(
                      controller: _searchController,
                      hintText: "Search @zentag, phone, bank ac. no. etc",
                      hintStyle: WidgetStateProperty.all(
                        TextStyle(color: AppColors.lightGrey, fontSize: 14),
                      ),
                      leading: const Icon(Icons.search, color: Colors.grey),
                      trailing: [
                        if (isSearching)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.main,
                              ),
                            ),
                          ),
                      ],
                      elevation: WidgetStateProperty.all(0),
                      backgroundColor: WidgetStateProperty.all(
                        AppColors.lightGrey.withAlpha(40),
                      ),
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 15.0),
                      ),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(200),
                        ),
                      ),
                      onChanged: _onSearchChanged, // 💡 Trigger debouncer here
                    ),

                    // 💡 Dynamic Fit and Scrollable Search Matches Box Layout
                    if (_searchController.text.isNotEmpty)
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 250, // 💡 Hard ceiling cap rule context
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.lightGrey.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: searchedContacts.isNotEmpty
                              ? SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: searchedContacts
                                        .map(
                                          (contact) =>
                                              _buildSearchedContactItem(
                                                contact,
                                              ),
                                        )
                                        .toList(),
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
                                      style: AppStyles.text.copyWith(
                                        color: Colors.grey,
                                      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Recent Payments", style: AppStyles.header),
                    TextButton(
                      onPressed: paymentsHistory.length > 10 ? () {} : null,
                      child: const Text(
                        "See All",
                        style: TextStyle(color: AppColors.main, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Horizontal Recents ListView Row
              SizedBox(
                height: 95,
                child: paymentsHistory.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                        itemCount: paymentsHistory.length,
                        itemBuilder: (context, index) {
                          return _buildRecentContactItem(
                            paymentsHistory[index],
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          "No recent contacts",
                          style: AppStyles.text.copyWith(
                            color: AppColors.lightGrey,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              // 4. Billers Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Pay Bills", style: AppStyles.header),
                    const SizedBox(height: 10),

                    if (bills.isNotEmpty)
                      ...List.generate(
                        bills.length,
                        (index) => Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withAlpha(40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.receipt_long,
                              color: AppColors.secondary,
                            ),
                            title: Text(
                              bills[index]["provider_name"] ??
                                  "Utility Option #${index + 1}",
                            ),
                            subtitle: const Text("Tap to view details"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      bills[index]["amount"] ?? "No value",
                                      style: AppStyles.header.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      "Due: ${bills[index]["due"] ?? "No value"}",
                                      style: AppStyles.text.copyWith(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Text(
                            "No Providers yet",
                            style: AppStyles.text.copyWith(
                              color: AppColors.lightGrey,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // searched contacts ===============
  Widget _buildSearchedContactItem(Map<String, dynamic> contact) {
    Map<String, dynamic> paymentForm = {
      "amount": "",
      "currency_code": "",
      ...contact,
    };

    return GestureDetector(
      onTap: () async {
        Map<String, dynamic>? amount = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) =>
              EnterAmount(recipient: contact["name"] ?? "N/A"),
        );

        if (amount == null) return;

        setState(() {
          paymentForm["amount"] = amount["amount"];
          paymentForm["currency_code"] = amount["currency_code"];
        });

        if (!mounted) return;

        // confirm PIN
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) =>
              ConfirmPin(paymentForm: paymentForm),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              child: Icon(Icons.person, size: 30),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact["name"] ?? "N/A",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textBlack,
                    ),
                  ),

                  Text(
                    contact["type"] ?? "N/A",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w200,
                      color: AppColors.textBlack,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recent payments contacts ========================
  Widget _buildRecentContactItem(Map<String, dynamic> contact) {
    final String displayName = contact["name"] ?? "N/A";

    Map<String, dynamic> paymentForm = {
      "amount": "",
      "currency_code": "",
      ...contact,
    };

    return GestureDetector(
      onTap: () async {
        Map<String, dynamic>? amount = await showDialog<Map<String, dynamic>>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) =>
              EnterAmount(recipient: displayName),
        );

        setState(() {
          paymentForm["amount"] = amount?["amount"];
          paymentForm["currency_code"] = amount?["currency_code"];
        });

        if (!mounted) return;

        // confirm PIN
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) =>
              ConfirmPin(paymentForm: paymentForm),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
              child: Icon(Icons.person, size: 30),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 0,
              child: Text(
                displayName,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textBlack,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
