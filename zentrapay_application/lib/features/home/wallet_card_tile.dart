import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Gradient card-preview tile used for a user's virtual/physical cards.
/// Extracted from the retired ZPay "Wallet" tab so Home's "Your Cards"
/// section keeps the same professional visual, wired to real card data.
class WalletCardTile extends StatelessWidget {
  const WalletCardTile({super.key, required this.card, this.onTap});

  final Map<String, dynamic> card;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = card['cardName'] ?? card['name'] ?? 'ZentraPay Card';
    final maskedNumber = card['maskedNumber'] != null
        ? '•••• •••• •••• ${card['maskedNumber']}'
        : '•••• •••• •••• ${card['last4'] ?? '••••'}';
    final holder = card['cardHolder'] ?? card['holderName'] ?? name;
    final expiry = card['expiry'] ?? card['expiryDate'] ?? '--/--';
    final status = (card['status'] ?? 'active').toString().toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: AppTheme.spacingMd),
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        decoration: BoxDecoration(
          gradient: AppTheme.secondaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.credit_card, color: Colors.white, size: 28),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(40),
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Text(
                    status,
                    style: AppTheme.whiteBodySmall.copyWith(fontSize: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              maskedNumber,
              style: AppTheme.whiteDisplayMedium.copyWith(fontSize: 18),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Card Holder", style: AppTheme.whiteBodySmall),
                      Text(
                        holder.toString().toUpperCase(),
                        style: AppTheme.whiteHeadline.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Expires", style: AppTheme.whiteBodySmall),
                    Text(
                      expiry.toString(),
                      style: AppTheme.whiteHeadline.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
