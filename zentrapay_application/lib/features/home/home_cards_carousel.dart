import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/utils/Notifier.dart';
import 'package:zentrapay_application/main.dart';

import 'api_home_wallet_services.dart';

class HomeCardsCarousel extends StatefulWidget {
  const HomeCardsCarousel({super.key, required this.cards});

  final List<Map<String, dynamic>> cards;

  @override
  State<HomeCardsCarousel> createState() => _HomeCardsCarouselState();
}

class _HomeCardsCarouselState extends State<HomeCardsCarousel> {
  // Explanation: Adjusted viewportFraction to 0.48 so roughly 2 cards fit side-by-side cleanly without overflowing.
  final PageController _controller = PageController(viewportFraction: 0.48);
  int _index = 0;
  final List<dynamic> cardColors = [
    AppColors.purple,
    AppColors.blue,
    AppColors.green,
  ];

  List<Map<String, dynamic>> cards = [];

  final List<Map<String, dynamic>> _cards = [
    {
      "index": 0,
      "name": "OnePay Card",
      "color": AppColors.blue,
      "type": "Mastercard",
      "value": "GHS 2,234.34",
      'visible': false,
    },
    {
      "index": 1,
      "name": "Debt Card",
      "color": AppColors.purple,
      "type": "Visa",
      "value": "GHS 4,034.00",
      'visible': false,
    },
    {
      "index": 2,
      // Explanation: Fixed index mismatch from duplicate '1' to '2' to prevent range errors.
      "name": "Prepaid Card",
      "color": AppColors.green,
      "type": "Mastercard",
      "value": "GHS 3,563,234.50",
      'visible': false,
    },
  ];

  void loadVirtualCards() async {
    try {
      final cardsResponse = await getVirtualCards();
      if (!cardsResponse?['success']) {
        return print("ERROR:: RECEIVED THIS:: $cardsResponse");
      }
      setState(() {
        cards = List<Map<String, dynamic>>.from(cardsResponse?["data"]);
      });
      return;
    } catch (e) {
      return print("SOMETHING WENT WRONG:: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadVirtualCards();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final cardHeight = isTablet
        ? 200.0
        : 120.0; // Explanation: Increased height to accommodate multi-row layouts.
    final cardPadding = isTablet
        ? 24.0
        : 12.0; // Explanation: Reduced side margins slightly to allow dual page views smoothly.
    final cardFontSize = isTablet ? 18.0 : 16.0;
    final balanceFontSize = isTablet ? 10.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.lightGrey.withAlpha(50)),
              ),
            ),
            child: Text("Your Cards", style: AppStyles.header),
          ),
        ),
        SizedBox(
          height: cardHeight,
          // Explanation: Removed the invalid Expanded widget inside a SizedBox constraint block.
          child: cards.isNotEmpty
              ? Container(
                  padding: EdgeInsets.all(15),
                  child: Center(
                    child: Column(
                      children: [
                        Text("No Cards"),
                        ElevatedButton(
                          onPressed: () {
                            ZentraNotifier.success("Pressed", "Button pressed");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "New Card",
                            style: AppStyles.text.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: _cards.length,
                  padEnds: false,
                  physics: ScrollPhysics(),
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => _showCardDetails(context, _cards[i]),
                    child: _buildCard(
                      _cards[i],
                      cardColors[i % cardColors.length],
                      // Explanation: Safe modulo accessor preventing out-of-bound list lookups.
                      cardPadding: cardPadding,
                      cardFontSize: cardFontSize,
                      balanceFontSize: balanceFontSize,
                    ),
                  ),
                ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCard(
    Map<String, dynamic> data,
    Color cardColor, {
    double cardPadding = 20,
    double cardFontSize = 18,
    double balanceFontSize = 18,
  }) => Card(
    margin: EdgeInsets.only(left: cardPadding),
    color: cardColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['name'] ?? "N/A",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: cardFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.credit_card, color: Colors.amber, size: cardFontSize),
            ],
          ),
          const Spacer(),
          Text(
            "****3456",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Exp: 24/29",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: cardFontSize * 0.7,
                ),
              ),
              Text(
                "CVV: 234",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: cardFontSize * 0.7,
                ),
              ),
              Row(
                children: [
                  CircleAvatar(
                    radius: cardFontSize * 0.4,
                    backgroundColor: Colors.red.withAlpha(200),
                  ),
                  Transform.translate(
                    offset: Offset(-cardPadding * 0.25, 0),
                    child: CircleAvatar(
                      radius: cardFontSize * 0.4,
                      backgroundColor: Colors.orange.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _showCardDetails(BuildContext context, Map<String, dynamic> cardData) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              cardData['name'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              cardData['type'],
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Text(
              cardData['value'],
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: cardData['color'],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDetailItem("Status", "Active"),
                _buildDetailItem("Expiry", "24/29"),
                _buildDetailItem("CVV", "***"),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.main,
                  foregroundColor: AppColors.primary,
                ),
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
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildControls(totalCards) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        onPressed: () => _controller.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        ),
        icon: const Icon(Icons.chevron_left, color: Colors.grey),
      ),
      Row(
        children: List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _index == i ? AppColors.main : Colors.grey[300],
            ),
          ),
        ),
      ),
      IconButton(
        onPressed: () => _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.ease,
        ),
        icon: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    ],
  );
}
