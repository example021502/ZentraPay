import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';

/// Plays a Learn & Earn tutorial: the video at [Tutorial.videoUrl] in an in-app
/// web view, with the title, length and description underneath. A video that
/// cannot be loaded (bad link, offline) shows a message with a Retry instead of a
/// blank screen.
class TutorialPlayerScreen extends StatefulWidget {
  const TutorialPlayerScreen({super.key, required this.tutorial});

  final Tutorial tutorial;

  static Future<void> show(BuildContext context, Tutorial tutorial) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TutorialPlayerScreen(tutorial: tutorial)),
    );
  }

  @override
  State<TutorialPlayerScreen> createState() => _TutorialPlayerScreenState();
}

class _TutorialPlayerScreenState extends State<TutorialPlayerScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _failed = false;

  Uri? get _videoUri {
    final uri = Uri.tryParse(widget.tutorial.videoUrl.trim());
    final ok = uri != null && (uri.scheme == 'https' || uri.scheme == 'http') && uri.host.isNotEmpty;
    return ok ? uri : null;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            // Only the main page failing means the video itself could not load
            if (error.isForMainFrame != false && mounted) {
              setState(() {
                _loading = false;
                _failed = true;
              });
            }
          },
        ),
      );
    _load();
  }

  void _load() {
    final uri = _videoUri;
    if (uri == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
    });
    _controller.loadRequest(uri);
  }

  String get _length {
    final s = widget.tutorial.durationSeconds;
    if (s <= 0) return '';
    final m = s ~/ 60;
    final rest = s % 60;
    return m > 0 ? '$m min${rest > 0 ? ' $rest s' : ''}' : '$s s';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tutorial;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: Text(t.title, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (!_failed) WebViewWidget(controller: _controller),
                    if (_loading)
                      const Center(child: CircularProgressIndicator()),
                    if (_failed)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white70, size: 32),
                              const SizedBox(height: 8),
                              const Text(
                                "We couldn't load this video.",
                                style: TextStyle(color: Colors.white70),
                              ),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title, style: AppTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      [t.type, _length].where((s) => s.isNotEmpty).join(' · '),
                      style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(t.description, style: AppTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
