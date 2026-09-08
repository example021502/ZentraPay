import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/features/home/repository/cache_homeData.dart';

import '../../core/theme/app_theme.dart';
import '../../main.dart';

/// Carrier model for picked recipient details.
class SelectedRecipient {
  final String displayName;
  final String? phoneNumber;

  const SelectedRecipient({required this.displayName, this.phoneNumber});

  factory SelectedRecipient.fromSearch(SearchAppUser user) => SelectedRecipient(
    displayName: user.fullName,
    phoneNumber: user.phoneNumber,
  );
}

/// Recipient selection widget updated to handle different payout options contextually.
class TransferUserSelection extends StatefulWidget {
  final ValueChanged<SelectedRecipient> onRecipientSelected;
  final String payoutOption;

  const TransferUserSelection({
    super.key,
    required this.onRecipientSelected,
    required this.payoutOption,
  });

  @override
  State<TransferUserSelection> createState() => _TransferUserSelectionState();
}

class _TransferUserSelectionState extends State<TransferUserSelection> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<SearchAppUser> _results = [];
  bool _searching = false;
  bool _hasQuery = false;

  static final RegExp _phoneLike = RegExp(r'^[+0-9\s-]+$');

  @override
  void initState() {
    super.initState();
    // Wrap ensureLoaded in a post-frame callback to prevent calling
    // setState or notifying listeners during the active build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TransactionsRepository.instance.ensureLoaded().catchError((_) {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  /// Returns dynamic hint text based on the selected payout channel.
  String _getHintText() {
    if (widget.payoutOption == 'Zentrapay Wallet') {
      return "Search by name, phone or @zentag";
    } else if (widget.payoutOption.contains('Mobile Money') ||
        widget.payoutOption == 'M-Pesa') {
      return "Enter mobile number or recipient name";
    } else {
      return "Enter bank account number or name";
    }
  }

  /// Handles debounce search input for users.
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _hasQuery = false;
        _results = [];
        _searching = false;
      });
      return;
    }
    setState(() {
      _hasQuery = true;
      _searching = true;
    });
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final result = await SearchRepository.search(query.trim());
        if (!mounted) return;
        setState(() {
          _results = result.appUsers;
          _searching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _results = [];
          _searching = false;
        });
      }
    });
  }

  SelectedRecipient? _recentFromTransaction(AppTransaction tx) {
    final identifier = tx.receiverId;
    final name = tx.receiverName;
    if (identifier.isEmpty || name.isEmpty) {
      return null;
    }
    return SelectedRecipient(displayName: name, phoneNumber: identifier);
  }

  List<AppTransaction> _recentInternalTransfers(List<AppTransaction> items) {
    final seen = <String>{};
    final recent = <AppTransaction>[];
    for (final tx in items) {
      if (tx.transactionType != 'TRANSFER_INTERNAL') continue;
      final identifier = tx.receiverId;
      if (identifier.isEmpty || !seen.add(identifier)) {
        continue;
      }
      recent.add(tx);
      if (recent.length >= 5) break;
    }
    return recent;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _searchBar(),
        const SizedBox(height: 15),
        if (_hasQuery) _searchResults() else _recentHistory(),
      ],
    );
  }

  /// Builds the search input text field.
  Widget _searchBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: AppTheme.gray50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.lightGrey),
    ),
    child: TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        icon: const Icon(Icons.search, size: 20, color: AppColors.textBlack),
        contentPadding: EdgeInsets.zero,
        hintText: _getHintText(),
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        border: InputBorder.none,
        suffixIcon: _searching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
      ),
    ),
  );

  /// Builds the search results list container.
  Widget _searchResults() {
    if (_searching && _results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text("Searching...")),
      );
    }
    if (_results.isEmpty) {
      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "No direct internal user matched. Use manual target info:",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          _userTile(
            title: _searchController.text,
            subtitle: widget.payoutOption,
            onTap: () {
              final query = _searchController.text.trim();
              final isPhone = _phoneLike.hasMatch(query);
              widget.onRecipientSelected(
                SelectedRecipient(
                  displayName: query,
                  phoneNumber: isPhone ? query : null,
                ),
              );
            },
          ),
        ],
      );
    }
    return Column(
      children: _results
          .map(
            (user) => _userTile(
              title: user.fullName,
              subtitle: user.phoneNumber,
              onTap: () => widget.onRecipientSelected(
                SelectedRecipient.fromSearch(user),
              ),
            ),
          )
          .toList(),
    );
  }

  /// Builds recent transaction history items.
  Widget _recentHistory() {
    return ListenableBuilder(
      listenable: TransactionsRepository.instance,
      builder: (context, _) {
        final repo = TransactionsRepository.instance;
        if (repo.isLoading && repo.items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final recents = _recentInternalTransfers(repo.items);
        if (recents.isEmpty) {
          return const Text(
            "No recent transfers yet",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent history",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: recents
                  .map(
                    (tx) => _recent(
                      tx.receiverName,
                      onTap: () {
                        final recipient = _recentFromTransaction(tx);
                        if (recipient != null) {
                          widget.onRecipientSelected(recipient);
                        }
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }

  /// Reusable user list tile UI element.
  Widget _userTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: AppTheme.gray50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.lightGrey),
    ),
    child: ListTile(
      leading: const Icon(Icons.person_outline, color: AppColors.textBlack),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      onTap: onTap,
    ),
  );

  /// Reusable recent contact avatar bubble.
  Widget _recent(String name, {required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: AppTheme.gray50,
          child: Icon(Icons.person_outline, color: AppColors.textBlack),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 60,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textBlack),
          ),
        ),
      ],
    ),
  );
}
