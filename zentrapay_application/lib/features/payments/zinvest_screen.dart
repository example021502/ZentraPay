import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'widgets/zinvest_header.dart';
import 'widgets/auto_invest_card.dart';
import 'widgets/investment_chart.dart';
import 'widgets/investment_list.dart';

class ZInvestScreen extends StatelessWidget {
  const ZInvestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.main,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const ZInvestHeader(),
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: const Column(
                children: [
                  AutoInvestCard(),
                  InvestmentChart(),
                  InvestmentList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
