import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/repositories/search_repository.dart';
import 'package:zentrapay_application/core/repositories/transactions_repository.dart';

/// The recipient the user picked, either from a live search hit or from
/// "Recent history". Carries exactly one of [phoneNumber]/[zentag] — the
/// same either/or shape PaymentsService.payInternal expects.
class SelectedRecipient {
  final String displayName;
  final String? phoneNumber;
  final String? zentag;

  const SelectedRecipient({
    required this.displayName,
    this.phoneNumber,
    this.zentag,
  });

  /// Zentag is the app's own @handle for wallet-to-wallet transfers, so it's
  /// preferred over phone number when a search hit carries both.
  factory SelectedRecipient.fromSearch(SearchAppUser user) => SelectedRecipient(
    displayName: user.fullName,
    zentag: user.zentag.isNotEmpty ? user.zentag : null,
    phoneNumber: user.zentag.isEmpty ? user.phoneNumber : null,
  );
}

/// In-app transfer recipient picker: live search over ZentraPay users plus a
/// "Recent history" strip derived from past internal-transfer transactions.
///
/// NOTE on "Recent history": AppTransaction only stores a flattened
/// `counterpartyIdentifier` (the backend collapses phoneNumber/zentag into
/// one column once the transaction is recorded), so there's no clean way to
/// know which of the two it originally was. Rather than falling back to
/// session-only "recently searched" (which would lose recents across app
/// restarts), this uses the real transaction history and applies a small
/// heuristic — digits/+/spaces only reads as a phone number, anything else
/// is treated as a zentag — to route it back into payInternal correctly.
class TransferUserSelection extends StatefulWidget {
  final ValueChanged<SelectedRecipient> onRecipientSelected;

  const TransferUserSelection({super.key, required this.onRecipientSelected});

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
    // Best-effort: recent history is a nice-to-have, not the primary
    // function of this screen, so a failed fetch shouldn't surface an error
    // over the recipient search.
    TransactionsRepository.instance.ensureLoaded().catchError((_) {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

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
    final identifier = tx.counterpartyIdentifier;
    final name = tx.counterpartyName;
    if (identifier == null || identifier.isEmpty || name == null || name.isEmpty) {
      return null;
    }
    final isPhone = _phoneLike.hasMatch(identifier);
    return SelectedRecipient(
      displayName: name,
      phoneNumber: isPhone ? identifier : null,
      zentag: isPhone ? null : identifier,
    );
  }

  List<AppTransaction> _recentInternalTransfers(List<AppTransaction> items) {
    final seen = <String>{};
    final recents = <AppTransaction>[];
    for (final tx in items) {
      if (tx.typeCode != 'TRANSFER_INTERNAL') continue;
      final identifier = tx.counterpartyIdentifier;
      if (identifier == null || identifier.isEmpty || !seen.add(identifier)) {
        continue;
      }
      recents.add(tx);
      if (recents.length >= 5) break;
    }
    return recents;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _searchBar(),
          const SizedBox(height: 15),
          if (_hasQuery) _searchResults() else _recentHistory(),
        ],
      ),
    );
  }

  Widget _searchBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        icon: const Icon(Icons.search, size: 20),
        hintText: "Search by name, phone or @zentag",
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

  Widget _searchResults() {
    if (_searching && _results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text("Searching...")),
      );
    }
    if (_results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text("No matches found", style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return Column(
      children: _results
          .map(
            (user) => _userTile(
              title: user.fullName,
              subtitle: user.zentag.isNotEmpty ? user.zentag : user.phoneNumber,
              onTap: () =>
                  widget.onRecipientSelected(SelectedRecipient.fromSearch(user)),
            ),
          )
          .toList(),
    );
  }

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
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: recents
                  .map(
                    (tx) => _recent(
                      tx.counterpartyName ?? "N/A",
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

  Widget _userTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
    ),
    child: ListTile(
      leading: const Icon(Icons.person_outline),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: subtitle.isNotEmpty
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      onTap: onTap,
    ),
  );

  Widget _recent(String name, {required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        const CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xFFF5F5F5),
          child: Icon(Icons.person_outline, color: Colors.black54),
        ),
        const SizedBox(height: 5),
        SizedBox(
          width: 60,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    ),
  );
}
