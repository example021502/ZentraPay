import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class HomeCardsCarousel extends StatefulWidget {
  const HomeCardsCarousel({super.key});

  @override
  State<HomeCardsCarousel> createState() => _HomeCardsCarouselState();
}

class _HomeCardsCarouselState extends State<HomeCardsCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

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
      "index": 1,
      "name": "Prepaid Card",
      "color": AppColors.green,
      "type": "Mastercard",
      "value": "GHS 3,563,234.50",
      'visible': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;
    final horizontalPadding = isTablet ? 40.0 : 20.0;
    final titleFontSize = isTablet ? 20.0 : 16.0;
    final cardHeight = isTablet ? 220.0 : 190.0;
    final cardPadding = isTablet ? 24.0 : 20.0;
    final cardFontSize = isTablet ? 20.0 : 18.0;
    final balanceFontSize = isTablet ? 22.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            25,
            horizontalPadding,
            15,
          ),
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
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: _cards.length,
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => _showCardDetails(context, _cards[i]),
              child: _buildCard(
                _cards[i],
                cardPadding: cardPadding,
                cardFontSize: cardFontSize,
                balanceFontSize: balanceFontSize,
              ),
            ),
          ),
        ),
        _buildControls(),
      ],
    );
  }

  Widget _buildCard(
    Map<String, dynamic> data, {
    double cardPadding = 20,
    double cardFontSize = 18,
    double balanceFontSize = 18,
  }) => Card(
    margin: EdgeInsets.symmetric(horizontal: cardPadding),
    color: data['color'],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    child: Padding(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['name'],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Balance",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: cardFontSize * 0.7,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        data['visible'] ? data['value'] ?? "N/A" : "----.--",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: balanceFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: cardPadding * 0.5),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _cards[_index]['visible'] =
                                !_cards[_index]['visible'];
                          });
                        },
                        child: Icon(
                          data['visible']
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.white70,
                          size: cardFontSize * 0.9,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
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
                  SizedBox(height: cardPadding * 0.25),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: cardFontSize * 0.5,
                        backgroundColor: Colors.red.withAlpha(200),
                      ),
                      Transform.translate(
                        offset: Offset(-cardPadding * 0.25, 0),
                        child: CircleAvatar(
                          radius: cardFontSize * 0.5,
                          backgroundColor: Colors.orange.withAlpha(200),
                        ),
                      ),
                    ],
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

  Widget _buildControls() => Row(
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
