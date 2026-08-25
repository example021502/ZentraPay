import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/repositories/transactions_repository.dart';
import 'package:zentrapay_application/core/utils/Common/FormatDateTimeString.dart';
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
      TransactionsRepository.instance.ensureLoaded();
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
      final description = (t.purpose)?.toLowerCase();
      return name.contains(_query) ||
          identifier.contains(_query) ||
          description!.contains(_query);
    }).toList();
  }

  IconData _getIconForType(String typeCode) {
    switch (typeCode) {
      case 'BILL_PAYMENT':
        return Icons.receipt_long;
      case 'BANK_TRANSFER':
      case 'WALLET_FUNDING':
        return Icons.account_balance;
      case 'CARD_PAYMENT':
        return Icons.credit_card;
      case 'REMITTANCE_SEND':
        return Icons.public;
      default:
        return Icons.person;
    }
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
                hintText: "Search transaction history...",
                hintStyle: WidgetStateProperty.all(
                  TextStyle(color: AppColors.lightGrey, fontSize: 14),
                ),
                leading: const Icon(Icons.search, color: Colors.grey),
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
              Text("Transaction History", style: AppStyles.header),
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
                      return Container(
                        alignment: Alignment.center,
                        height: 100,
                        child: Text(
                          "No history found",
                          style: AppStyles.text.copyWith(
                            color: AppColors.lightGrey,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.vertical,
                      physics: const BouncingScrollPhysics(),
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
    final displayIdentifier = transaction.receiverId;

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
            _getIconForType(transaction.transactionType),
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
          formatDateTimeString(transaction.createdAt),
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
            color: transaction.amount.startsWith("-")
                ? AppColors.main
                : AppColors.green,
          ),
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  void _showTransactionDetails(AppTransaction transaction) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
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
            _detailRow("Reference", transaction.internalReferenceId),
            _detailRow("Date", formatDateTimeString(transaction.createdAt)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
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
        Text(value, style: const TextStyle(color: AppColors.textBlack)),
      ],
    ),
  );
}
