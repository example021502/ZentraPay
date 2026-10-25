import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/auth/onboarding_page_widget.dart';
import 'package:zentrapay_application/features/auth/onboarding_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.headerPink,
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (v) => setState(() => _currentPage = v),
                itemCount: OnboardingData.slides.length,
                itemBuilder: (_, i) => OnboardingPageWidget(
                  title: OnboardingData.slides[i]["title"]!,
                  description: OnboardingData.slides[i]["desc"]!,
                  imageLink: OnboardingData.slides[i]["img"]!,
                ),
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: Text("Skip", style: TextStyle(color: AppTheme.buttonColor)),
          ),
          Row(children: List.generate(3, (i) => _dot(i))),
          TextButton(
            onPressed: () => _currentPage == 2
                ? Navigator.pushNamed(context, '/register')
                : _controller.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                  ),
            child: Text(
              _currentPage == 2 ? "Continue" : "Next",
              style: TextStyle(color: AppTheme.buttonColor),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _dot(int i) => Container(
    height: 8,
    width: _currentPage == i ? 24 : 8,
    margin: const EdgeInsets.only(right: 5),
    decoration: BoxDecoration(
      color: _currentPage == i ? AppTheme.buttonColor : Colors.grey[300],
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
