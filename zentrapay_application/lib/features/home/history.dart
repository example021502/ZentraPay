import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

import 'package:zentrapay_application/features/home/api_home_wallet_services.dart';

class PaymentHistory extends StatefulWidget {
  const PaymentHistory({super.key});

  @override
  State<PaymentHistory> createState() => _PaySectionMainState();
}

class _PaySectionMainState extends State<PaymentHistory> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool isSearching = false;

  // Comment: Master list holding all immutable payment records fetched from your database backend
  List<Map<String, dynamic>> paymentHistory = [];

  // Comment: Dynamic tracking list that feeds the UI list builder component directly
  List<Map<String, dynamic>> displayedHistory = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // Comment: Async pipeline assembling national and international records into state structures cleanly
  // Comment: Async pipeline assembling national and international records into state structures cleanly
  void _loadHistory() async {
    try {
      // 1. Fetch the raw Dio Response object from your API caller
      final response = await getHistory();
      if (!mounted) return;

      // 2. Check if the response or its internal payload body data is completely missing
      if (response == null || response.data == null) {
        debugPrint("History payload returned empty or invalid response.");
        return;
      }

      // 3. Extract the map data safely from the response payload body
      final Map<String, dynamic> history = Map<String, dynamic>.from(
        response.data,
      );

      setState(() {
        // Comment: Explicitly casting values with safe null collection fallbacks to avoid map crashes
        final List<dynamic> national = history['national'] ?? [];
        final List<dynamic> international = history['international'] ?? [];

        paymentHistory = List<Map<String, dynamic>>.from([
          ...national,
          ...international,
        ]);

        // Comment: Make sure to fill the UI layout stream with initial values on launch state
        displayedHistory = List.from(paymentHistory);
      });
    } catch (e) {
      debugPrint("ERROR OCCURRED!: $e");
    }
  }

  // Comment: Timed debounce processing layer reducing overhead operations on target system architectures
  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        displayedHistory = List.from(paymentHistory);
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Comment: Polymorphic evaluation filtering out record objects matching the target query input
      final filtered = paymentHistory.where((item) {
        final name = (item["name"] ?? "").toString().toLowerCase();
        final identifier = (item["identifier"] ?? "").toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            identifier.contains(query.toLowerCase());
      }).toList();

      setState(() {
        displayedHistory = filtered;
        isSearching = false;
      });
    });
  }

  // Comment: Dynamic graphic lookup mapping specific icon assets to backend entity type parameters
  IconData _getIconForType(String type) {
    switch (type) {
      case 'bill_provider':
        return Icons.receipt_long;
      case 'linked_bank':
        return Icons.account_balance;
      case 'app_user':
      default:
        return Icons.person;
    }
  }

  // Comment: Gateway navigation router identifying target transaction flows using metadata structures
  void _handleOnContactTap(Map<String, dynamic> contact) {
    final String type = contact["type"] ?? "app_user";
    final String targetName = contact["name"] ?? "N/A";
    final String targetIdentifier = contact["identifier"] ?? "";

    switch (type) {
      case 'bill_provider':
        debugPrint(
          "Routing to Paystack payment sheet configuration for $targetName ($targetIdentifier)",
        );
        break;
      case 'linked_bank':
        debugPrint(
          "Routing to Bank withdrawal validation screen for account: $targetName",
        );
        break;
      case 'app_user':
        debugPrint(
          "Routing to Peer-To-Peer local payment balance validation screen for $targetName",
        );
        break;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SearchBar(
                controller: _searchController,
                hintText: "Search recent payments...",
                hintStyle: WidgetStateProperty.all(
                  TextStyle(color: AppColors.lightGrey, fontSize: 14),
                ),
                leading: const Icon(Icons.search, color: Colors.grey),
                trailing: [
                  if (isSearching)
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
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
                  AppColors.lightGrey.withValues(alpha: 0.15),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 15.0),
                ),
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(200),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),

              const SizedBox(height: 20),
              Text("Recent Payments", style: AppStyles.header),
              const SizedBox(height: 10),

              // Comment: Main vertical list displaying filtered data or a safe empty fallback widget layout
              Expanded(
                child: displayedHistory.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.vertical,
                        physics: const BouncingScrollPhysics(),
                        itemCount: displayedHistory.length,
                        itemBuilder: (context, index) {
                          return _buildRecentContactItem(
                            displayedHistory[index],
                          );
                        },
                      )
                    : Container(
                        alignment: Alignment.center,
                        height: 100,
                        child: Text(
                          isSearching
                              ? "Searching records..."
                              : "No history found",
                          style: AppStyles.text.copyWith(
                            color: AppColors.lightGrey,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Comment: Standardized design container blueprint rendering unified payment node cards
  Widget _buildRecentContactItem(Map<String, dynamic> contact) {
    final String displayName = contact["name"] ?? "N/A";
    final String displayIdentifier = contact["identifier"] ?? "";
    final String type = contact["type"] ?? "app_user";

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
          child: Icon(
            _getIconForType(type),
            size: 22,
            color: AppColors.secondary,
          ),
        ),
        title: Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        subtitle: Text(
          displayIdentifier,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.lightGrey,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.lightGrey,
          size: 20,
        ),
        onTap: () => _handleOnContactTap(contact),
      ),
    );
  }
}
