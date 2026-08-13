import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/transaction.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

class RecentPaymentsList extends StatelessWidget {
  final List<AppTransaction> recentPayments;
  final ValueChanged<AppTransaction> onSelectTransaction;

  const RecentPaymentsList({
    super.key,
    required this.recentPayments,
    required this.onSelectTransaction,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 95,
      child: recentPayments.isNotEmpty
          ? ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 16.0, right: 8.0),
              itemCount: recentPayments.length,
              itemBuilder: (context, index) {
                final transaction = recentPayments[index];
                final displayName = transaction.counterpartyName ?? "Unknown";

                return GestureDetector(
                  onTap: () => onSelectTransaction(transaction),
                  child: Container(
                    margin: const EdgeInsets.only(right: 15.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 70,
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTheme.labelLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Text(
                "No recent contacts",
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
              ),
            ),
    );
  }
}
