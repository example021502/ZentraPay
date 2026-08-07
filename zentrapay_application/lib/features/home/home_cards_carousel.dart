import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';

import 'wallet_card_tile.dart';

class HomeCardsCarousel extends StatefulWidget {
  const HomeCardsCarousel({super.key, required this.cards});

  final List<Map<String, dynamic>> cards;

  @override
  State<HomeCardsCarousel> createState() => _HomeCardsCarouselState();
}

class _HomeCardsCarouselState extends State<HomeCardsCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.72);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Your Cards", style: AppTheme.titleLarge),
        Container(
          constraints: BoxConstraints(maxHeight: 200),

          child: widget.cards.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.credit_card_off_outlined,
                  message: "No Cards",
                  actionLabel: "New Card",
                  onAction: () => showComingSoon(context, "New Card"),
                )
              : PageView.builder(
                  controller: _controller,
                  itemCount: widget.cards.length,
                  padEnds: false,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(left: AppTheme.spacingMd),
                    child: WalletCardTile(
                      card: widget.cards[i],
                      onTap: () => _showCardDetails(context, widget.cards[i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _showCardDetails(BuildContext context, Map<String, dynamic> cardData) {
    final name = cardData['cardName'] ?? cardData['name'] ?? 'ZentraPay Card';
    final type = cardData['type'] ?? cardData['cardType'] ?? 'Card';
    final status = (cardData['status'] ?? 'active').toString();
    final expiry = cardData['expiry'] ?? cardData['expiryDate'] ?? '--/--';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.gray300,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(name.toString(), style: AppTheme.headlineMedium),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              type.toString(),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem("Status", status),
                _buildDetailItem("Expiry", expiry.toString()),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
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

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(value, style: AppTheme.titleLarge),
      ],
    );
  }
}
