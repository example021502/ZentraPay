import 'package:flutter/material.dart';
import 'package:zentrapay_application/main.dart';
import 'package:zentrapay_application/onboarding/onboarding_page_widget.dart';
import 'package:zentrapay_application/onboarding/onboarding_data.dart';

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
      backgroundColor: AppColors.main,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            child: const Text(
              "Skip",
              style: TextStyle(color: AppColors.secondary),
            ),
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
              style: const TextStyle(color: AppColors.secondary),
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
      color: _currentPage == i ? AppColors.secondary : Colors.grey[300],
      borderRadius: BorderRadius.circular(4),
    ),
  );
}
