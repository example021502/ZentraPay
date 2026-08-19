import 'dart:async';

import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/main.dart';

import '../../core/theme/navigation_bar/responsive_navigation.dart';

// Comment: Import the file where ResponsiveNavigation widget is defined.
// Replace 'path/to/your_navigation_file.dart' with the actual path if it's not in main.dart
// import 'package:zentrapay_application/path/to/your_navigation_file.dart';

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

    // Comment: Phase 2 (0.3 to 0.8) - Brand name slides horizontally over 2 seconds, starting mid-way through logo pop
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

    // Comment: Phase 3 (0.5 to 1.0) - Slogan drops vertically downward over 2 seconds, concluding right at the 4-second mark
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

  // Comment: Cleaned up signature syntax to resolve compiler syntax errors completely
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          // Comment: Passes decoded user claims payload directly to destination layout wrapper
          builder: (context) => ResponsiveNavigation(userData: userData),
        ),
      );
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
      // Comment: Set background directly on Scaffold to avoid sizing conflicts
      body: SafeArea(
        child: SizedBox.expand(
          // Comment: Force full screen height safely without infinite height or scrolling collisions
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            // Comment: Center everything vertically
            children: [
              // Comment: Interactive staggered layer hierarchy
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.centerLeft,
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            height: MediaQuery.of(context).size.height,
                            width: MediaQuery.of(context).size.width,
                            child: Image.asset("images/SplashscreenImage"),
                          ),
                          // Comment: "entrapay" positioned behind Z visually via layer structure
                          SlideTransition(
                            position: _brandSlide,
                            child: FadeTransition(
                              opacity: _brandOpacity,
                              child: const Padding(
                                padding: EdgeInsets.only(left: 65),
                                child: Text(
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
                          ),

                          // Comment: Z Logo positioned below text layout in tree so it sits "on top"
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
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Comment: ClipRect hides the text while its offset is vertically "above" the layout space
                  ClipRect(
                    child: SlideTransition(
                      position: _sloganSlide,
                      child: FadeTransition(
                        opacity: _sloganOpacity,
                        child: const Text(
                          'One Africa, One Wallet',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Comment: Render conditional loading indicator cleanly beneath branding components
              if (_isLoading) ...[
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: AppColors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
