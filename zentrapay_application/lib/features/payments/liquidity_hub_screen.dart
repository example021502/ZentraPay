import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';

class LiquidityHubScreen extends StatefulWidget {
  const LiquidityHubScreen({super.key});

  @override
  State<LiquidityHubScreen> createState() => _LiquidityHubScreenState();
}

class _LiquidityHubScreenState extends State<LiquidityHubScreen> {
  int currentCurrencyIndex = 0;

  final List<Map<String, dynamic>> currencies = [
    {'code': 'GHSC', 'name': 'Ghanaian Cedi', 'flag': '🇬🇭'},
    {'code': 'USDC', 'name': 'US Dollar', 'flag': '🇺🇸'},
    {'code': 'KShC', 'name': 'Kenyan Shilling', 'flag': '🇰🇪'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.main,
      appBar: AppBar(
        backgroundColor: AppColors.main,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Global Liquidity Hub",
          style: TextStyle(color: AppColors.primary, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 20),
            _buildCurrencyTabs(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildLiquidityProfile(),
            const SizedBox(height: 20),
            _buildFinancialTrend(),
            const SizedBox(height: 20),
            _buildLiquidityCore(),
            const SizedBox(height: 20),
            _buildTopRisks(),
            const SizedBox(height: 20),
            _buildRecentAlerts(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.main, AppColors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ZentraPay Global\nLiquidity Hub",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "ZentraPay Unified Wallet",
            style: TextStyle(fontSize: 14, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                "GHSC 3,378,345,245.90",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Row(
        children: currencies.asMap().entries.map((entry) {
          final index = entry.key;
          final currency = entry.value;
          final isSelected = index == currentCurrencyIndex;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => currentCurrencyIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.main : AppColors.lightGrey,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      currency['flag'],
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currency['code'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.main
                            : AppColors.textBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionItem(Icons.payment, "Trigger\nPayment"),
          _buildActionItem(Icons.sync, "Convert\nJust-In-Time"),
          _buildActionItem(Icons.schedule, "Instant\nSettlement"),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.main,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildLiquidityProfile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Global Liquidity Profile",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCircularMetric(
                "90.1%",
                "Trapped Liquidity\nMinimized",
                0.901,
              ),
              _buildCircularMetric("88.0%", "Capital Efficiency", 0.88),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularMetric(String value, String label, double progress) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: AppColors.lightGrey,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.green,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textBlack,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.textBlack),
        ),
      ],
    );
  }

  Widget _buildFinancialTrend() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Financial Exposure Trend (2026)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 150,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lightGrey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.show_chart,
              size: 100,
              color: AppColors.main,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiquidityCore() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Global Liquidity Core",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          _buildCoreItem(
            Icons.lightbulb,
            "AI-Liquidity Optimization",
            "Leverage AI to forecast cash flow and optimize your capital deployments.",
            "2 notifications",
          ),
          const SizedBox(height: 12),
          _buildCoreItem(
            Icons.public,
            "Global Liquidity Marketplace",
            "Generate yield on idle capital through regulated liquidity solutions.",
            null,
          ),
          const SizedBox(height: 12),
          _buildCoreItem(
            Icons.language,
            "Multi-Country Settlement Engine",
            "Facilitate seamless payments to suppliers, employees and partners globally.",
            null,
          ),
        ],
      ),
    );
  }

  Widget _buildCoreItem(
    IconData icon,
    String title,
    String description,
    String? notification,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.main.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.main, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textBlack,
                  ),
                ),
                if (notification != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications,
                        size: 12,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        notification,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: AppColors.textBlack,
          ),
        ],
      ),
    );
  }

  Widget _buildTopRisks() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Top Risks",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          _buildRiskItem(
            Icons.trending_up,
            "Market Volatility",
            "Risk Score",
            74,
            AppColors.orange,
          ),
          const SizedBox(height: 12),
          _buildRiskItem(
            Icons.account_balance,
            "Credit Default",
            "Risk Score",
            45,
            AppColors.orange,
          ),
          const SizedBox(height: 12),
          _buildRiskItem(
            Icons.warning,
            "Reports",
            "Risk Score",
            23,
            AppColors.main,
          ),
        ],
      ),
    );
  }

  Widget _buildRiskItem(
    IconData icon,
    String title,
    String subtitle,
    int score,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textBlack, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textBlack,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textBlack,
                ),
              ),
            ],
          ),
        ),
        Text(
          "$score",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAlerts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
          bottom: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Recent Alerts",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textBlack,
            ),
          ),
          const SizedBox(height: 16),
          _buildAlertItem(
            Icons.notifications,
            "Critical Notification",
            "3 Minutes ago",
            AppColors.main,
          ),
          const SizedBox(height: 12),
          _buildAlertItem(
            Icons.notifications,
            "Critical Notification",
            "3 Minutes ago",
            AppColors.main,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(
    IconData icon,
    String title,
    String time,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textBlack,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
