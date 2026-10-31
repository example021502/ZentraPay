import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/core/utils/Common/format_date_time_string.dart';
import 'package:zentrapay_application/features/home/HomePayments/send_again_flow.dart';
import 'package:zentrapay_application/main.dart';

class PaymentHistory extends StatefulWidget {
  const PaymentHistory({super.key});

  @override
  State<PaymentHistory> createState() => _PaymentHistoryState();
}

class _PaymentHistoryState extends State<PaymentHistory> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // Defer repository load so it doesn't trigger state updates during the active build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ensureLoaded rethrows on failure; unhandled here it became an
      // "unhandled exception" that still left the list permanently empty.
      TransactionsRepository.instance.ensureLoaded().catchError(
        (Object e) => debugPrint('History load failed: $e'),
      );
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      TransactionsRepository.instance.loadNextPage();
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _query = query.trim().toLowerCase());
  }

  List<AppTransaction> _filter(List<AppTransaction> items) {
    if (_query.isEmpty) return items;
    return items.where((t) {
      final name = (t.receiverName).toLowerCase();
      final identifier = (t.receiverId).toLowerCase();
      final reference = (t.txnRef).toLowerCase();
      final amount = (t.amount).toLowerCase();

      return name.contains(_query) ||
          identifier.contains(_query) ||
          reference.contains(_query) ||
          amount.contains(_query);
    }).toList();
  }

  // Comment: the amount string from the backend carries a credit/debit sign
  // ("+GHS 100.00" / "-GHS 100.00") — the sign picks the arrow direction.
  IconData _getIcon(AppTransaction transaction) {
    if (transaction.isDebit) return Icons.call_made_rounded;
    return Icons.call_received_rounded;
  }

  // Comment: debits render in the app's main color, credits in green.
  Color _getColor(AppTransaction transaction) {
    if (transaction.isCredit) return AppColors.green;
    return AppColors.main;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SearchBar(
                controller: _searchController,
                hintText: "Search transaction history...",
                hintStyle: WidgetStateProperty.all(
                  TextStyle(color: AppColors.lightGrey, fontSize: 14),
                ),
                leading: Icon(Icons.search, color: AppTheme.textBlack),
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
              Text(
                "History",
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListenableBuilder(
                  listenable: TransactionsRepository.instance,
                  builder: (context, _) {
                    final repo = TransactionsRepository.instance;
                    final displayed = _filter(repo.items);

                    if (repo.isLoading && repo.items.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.main),
                      );
                    }

                    if (displayed.isEmpty) {
                      final err = repo.error;
                      print("FAILED TO LOAD THE HISTORY:: $err");
                      return Container(
                        alignment: Alignment.center,
                        height: 100,
                        child: Text(
                          // Distinguish "genuinely no transactions" from
                          // "the request/parse failed" — these looked identical.
                          err != null
                              ? 'Could not load history.'
                              : "No history found",
                          textAlign: TextAlign.center,
                          style: AppStyles.text.copyWith(
                            color: AppColors.lightGrey,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.vertical,
                      // physics: const BouncingScrollPhysics(),
                      itemCount: displayed.length + (repo.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= displayed.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.main,
                                ),
                              ),
                            ),
                          );
                        }
                        return _buildTransactionItem(displayed[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Comment: Standardized design container blueprint rendering unified payment node cards
  Widget _buildTransactionItem(AppTransaction transaction) {
    final displayName = transaction.receiverName;
    // completedAt arrives as an ISO-8601 string; format it first so the row
    // matches the "YYYY-MM-DD • HH:mm" style used by home_transactions.
    final date = formatDateTimeString(transaction.completedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withAlpha(20),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: AppTheme.brand.withAlpha(20),
          child: Icon(
            _getIcon(transaction),
            size: 22,
            color: _getColor(transaction),
          ),
        ),
        title: Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textBlack,
          ),
        ),
        subtitle: Text(
          date,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.lightGrey,
          ),
        ),
        trailing: Text(
          transaction.amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            // The signed amount from the backend decides the color: a "-"
            // debit is outgoing (main), a "+" credit is incoming (green).
            color: transaction.isDebit ? AppColors.main : AppColors.green,
          ),
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  void _showTransactionDetails(AppTransaction transaction) {
    // Captured before the sheet opens: the sheet's own context is disposed
    // on pop, but the page context stays valid for launching the send-again
    // flow once the sheet is out of the way.
    final BuildContext pageContext = context;
    // Only outgoing rows record a real counterparty — an incoming payment
    // stores the user themself as receiver, so "Send Again" would prefill a
    // transfer to your own account (see canSendAgain).
    final bool showSendAgain = canSendAgain(transaction);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(transaction.receiverName, style: AppStyles.header),
            const SizedBox(height: 8),
            Text(
              transaction.amount,
              style: AppStyles.header.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 12),
            _detailRow("Status", transaction.status),
            _detailRow("Reference", transaction.txnRef),
            _detailRow("Date", formatDateTimeString(transaction.completedAt)),
            const SizedBox(height: 16),
            if (showSendAgain) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Close the details sheet first so the loading overlay
                    // and the amount screen own the stage from here on.
                    Navigator.pop(sheetContext);
                    await sendAgainFromTransaction(
                      context: pageContext,
                      transaction: transaction,
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text("Send Again"),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text("Close"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.lightGrey)),
        Text(value, style: TextStyle(color: AppColors.textBlack)),
      ],
    ),
  );
}
