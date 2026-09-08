import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/main.dart';

import '../../features/home/repository/cache_homeData.dart';
import '../../core/theme/navigation_bar/responsive_navigation.dart';

// Comment: Main splash screen widget handling initial app loading and route dispatching
class ZentrapaySplashScreenMain extends StatefulWidget {
  const ZentrapaySplashScreenMain({super.key});

  @override
  State<ZentrapaySplashScreenMain> createState() =>
      _ZentrapaySplashScreenMainState();
}

class _ZentrapaySplashScreenMainState extends State<ZentrapaySplashScreenMain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoScale;
  late Animation<Offset> _brandSlide;
  late Animation<double> _brandOpacity;
  late Animation<Offset> _sloganSlide;
  late Animation<double> _sloganOpacity;

  // Comment: Local state condition tracking variable to display loading context overlay
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Comment: Global animation clock lasting exactly 4 seconds
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Comment: Phase 1 (0.0 to 0.5) - Z Logo slowly pops into view over 2 seconds
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    // Comment: Phase 2 (0.3 to 0.8) - Brand name slides horizontally over 2 seconds
    _brandSlide = Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _brandOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.7, curve: Curves.easeIn),
      ),
    );

    // Comment: Phase 3 (0.5 to 1.0) - Slogan drops vertically downward over 2 seconds
    _sloganSlide = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _sloganOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeIn),
      ),
    );

    _runAnimationSequence();
  }

  // Comment: Check stored token validity asynchronously
  Future<Map<String, dynamic>?> _checkLoginStatus() async {
    try {
      final token = await SecureStorageService.getToken();
      if (token != null && token.isNotEmpty) {
        bool isExpired = JwtDecoder.isExpired(token);
        if (!isExpired) {
          return JwtDecoder.decode(token);
        }
      }
    } catch (e) {
      debugPrint("Error reading or decoding secure storage token: $e");
    }
    return null;
  }

  void _runAnimationSequence() async {
    // Comment: Trigger the staggered animations concurrently
    _controller.forward();

    // Comment: Fetch token parameters background status loop immediately
    final tokenCheckFuture = _checkLoginStatus();

    // Comment: Wait exactly 4 seconds for the complete animation timeline to finalize smoothly
    await Future.delayed(const Duration(seconds: 4));
    if (!mounted) return;

    // Comment: Display background loading state during the remaining 2-second hold window
    setState(() {
      _isLoading = true;
    });

    // Comment: Wait for the remaining 2 seconds (Total 6-second splash delay)
    await Future.delayed(const Duration(seconds: 2));
    final userData = await tokenCheckFuture;
    if (!mounted) return;

    // Comment: Evaluate calculated token parameters to navigate to the correct screen layout
    if (userData != null) {
      WalletsRepository.instance.ensureLoaded();
      BillProvidersRepository.instance.ensureLoaded();
      ServiceProvidersRepository.instance.ensureLoaded();
      TransactionsRepository.instance.ensureLoaded();
      Future.delayed(Duration(seconds: 3), () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // Comment: Passes decoded user claims payload directly to destination layout wrapper
            builder: (context) => ResponsiveNavigation(userData: userData),
          ),
        );
      });
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.main,
      // Comment: Force full screen height safely without infinite layout collisions
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Comment: 1. BACKGROUND IMAGE - Placed first in stack so it covers the entire page underneath everything
            if (MediaQuery.of(context).size.width < 470)
              Positioned.fill(
                child: Image.asset(
                  "images/SplashscreenImage.png",
                  fit: BoxFit.cover,
                ),
              ),
            // Comment: 2. CONTENT CONTAINER - Positioned at the top center with padding
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Comment: Row aligning Z Logo and text side-by-side cleanly at top center
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Comment: Z Logo container
                          ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Z',
                                style: TextStyle(
                                  color: AppColors.main,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 40,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          // Comment: Brand text sliding into place
                          SlideTransition(
                            position: _brandSlide,
                            child: FadeTransition(
                              opacity: _brandOpacity,
                              child: const Text(
                                'entrapay',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 35,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Comment: Slogan dropping down vertically beneath the brand name
                      ClipRect(
                        child: SlideTransition(
                          position: _sloganSlide,
                          child: FadeTransition(
                            opacity: _sloganOpacity,
                            child: const Text(
                              'One Africa, One Wallet',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                      // LOADING
                      if (_isLoading) ...[
                        const CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 30),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
