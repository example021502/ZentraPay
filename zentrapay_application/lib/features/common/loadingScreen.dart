import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key, required this.isLoading});

  final bool isLoading;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  // Boolean flag to control overlay visibility
  bool _isLoading = false;

  // Simulate an asynchronous operation like an API call
  Future<void> _performAsyncTask() async {
    setState(() {
      _isLoading = true; // Display the loading overlay
    });

    // Simulating a 3-second network delay
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isLoading = false; // Hide the loading overlay
    });
  }

  @override
  Widget build(BuildContext context) {
    // PortalTarget watches the visibility state and renders the follower accordingly
    return PortalTarget(
      visible: _isLoading,
      // Filled anchor ensures the portal follower covers the entire child layout
      anchor: const Filled(),
      portalFollower: ColoredBox(
        color: Colors.black.withAlpha(50),
        // Semi-transparent backdrop to block input
        child: const Center(
          child: CircularProgressIndicator(), // Active loading indicator
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _performAsyncTask,
              child: const Text('Start Loading'),
            ),
          ),
        ],
      ),
    );
  }
}
