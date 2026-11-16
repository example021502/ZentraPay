import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:paystack_flutter_sdk/paystack_flutter_sdk.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/wallet_topup/models/response_entities.dart';
import 'package:zentrapay_application/features/wallet_topup/topup_service.dart';

/// How a wallet top-up ended, as the BACKEND sees it (never as the gateway SDK claims).
enum TopupOutcome { success, pending, failed, cancelled }

/// Opens the payment gateway for a checkout the backend created, then asks the backend what
/// happened.
///
/// * **Paystack** — the native Paystack SDK, started with the `accessCode` the backend got from
///   Paystack (card / bank / mobile-money channels are chosen inside Paystack's own UI, so card or
///   wallet details never touch ZentraPay). If the SDK is unavailable the hosted pay page opens
///   in a WebView instead.
/// * **Flutterwave** — the hosted checkout link the backend created, in a WebView (this is what
///   Flutterwave's Flutter SDK does under the hood, but the amount and customer are fixed by our
///   server, not by the app).
///
/// A gateway callback is never trusted: money is only shown as received when
/// `GET /api/topup/verify/{reference}` says SUCCESS (the backend re-checks the amount with the
/// gateway before it credits the wallet).
class GatewayCheckout {
  GatewayCheckout._();

  static final Paystack _paystack = Paystack();
  static bool _paystackReady = false;

  /// Initialises the Paystack SDK once with the PUBLIC key from `.env`.
  static Future<bool> ensurePaystackReady() async {
    if (_paystackReady) return true;
    if (kIsWeb) return false;
    final key = TopupService.paystackPublicKey;
    if (!key.startsWith('pk_')) {
      debugPrint(
        'Paystack: set PAYSTACK_TEST_PK (pk_test_…) in the app .env — '
        'the SDK needs a PUBLIC key.',
      );
      return false;
    }
    try {
      _paystackReady = await _paystack.initialize(key, kDebugMode);
    } catch (e) {
      debugPrint('Paystack SDK init failed: $e');
      _paystackReady = false;
    }
    return _paystackReady;
  }

  /// Runs the whole top-up payment for [checkout] and resolves to the verified outcome.
  static Future<TopupOutcome> run(
    BuildContext context, {
    required TopupResponse checkout,
    required String gateway,
  }) async {
    final isPaystack = gateway.toLowerCase().contains('paystack');
    var userBackedOut = false;

    if (isPaystack &&
        (checkout.accessCode ?? '').isNotEmpty &&
        await ensurePaystackReady()) {
      try {
        final result = await _paystack.launch(checkout.accessCode!);
        userBackedOut = result.status.toLowerCase() == 'cancelled';
      } catch (e) {
        debugPrint('Paystack SDK launch failed, using hosted page: $e');
        if (!context.mounted) return TopupOutcome.failed;
        userBackedOut = !(await _openHostedPage(context, checkout));
      }
    } else {
      if (!context.mounted) return TopupOutcome.failed;
      userBackedOut = !(await _openHostedPage(context, checkout));
    }

    if (userBackedOut) {
      // Closing the sheet is not proof nothing was paid (the user may have paid and then closed),
      // so ask once; only report "cancelled" when the backend sees no payment either.
      final status = await _verify(checkout.reference, attempts: 1);
      return status == TopupOutcome.success ? status : TopupOutcome.cancelled;
    }
    return _verify(checkout.reference, attempts: 6);
  }

  // Hosted pay page in a WebView. Returns false when the user closed it without finishing.
  static Future<bool> _openHostedPage(
    BuildContext context,
    TopupResponse checkout,
  ) async {
    final url = checkout.authorizationUrl;
    if (url == null || url.isEmpty || kIsWeb) return false;
    final finished = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _HostedCheckoutScreen(url: url),
      ),
    );
    return finished == true;
  }

  /// Waits for the backend's verdict on [reference] (a charge that is not settled yet, e.g. a saved card).
  static Future<TopupOutcome> awaitOutcome(String reference, {int attempts = 6}) =>
      _verify(reference, attempts: attempts);

  // Polls the backend: the gateway often needs a few seconds before it reports the payment.
  static Future<TopupOutcome> _verify(
    String reference, {
    required int attempts,
  }) async {
    for (var i = 0; i < attempts; i++) {
      try {
        final result = await TopupService.verify(reference);
        switch (result.status.toUpperCase()) {
          case 'SUCCESS':
            return TopupOutcome.success;
          case 'FAILED':
            return TopupOutcome.failed;
        }
      } catch (e) {
        debugPrint('Top-up verify attempt ${i + 1} failed: $e');
      }
      if (i < attempts - 1) {
        await Future<void>.delayed(const Duration(seconds: 3));
      }
    }
    return TopupOutcome.pending;
  }
}

/// Full-screen WebView for a gateway's hosted checkout. Pops `true` once the gateway sends the
/// customer back to ZentraPay's callback URL (payment finished — whether it succeeded is decided
/// by the backend afterwards), or `false`/null when the user closes it.
class _HostedCheckoutScreen extends StatefulWidget {
  final String url;
  const _HostedCheckoutScreen({required this.url});

  @override
  State<_HostedCheckoutScreen> createState() => _HostedCheckoutScreenState();
}

class _HostedCheckoutScreenState extends State<_HostedCheckoutScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  // Where the gateways send the customer when they are done (application.properties:
  // paystack.callback-url / flutterwave.redirect-url) plus the checkout's own "close" links.
  static bool _isReturnUrl(String url) {
    final u = Uri.tryParse(url);
    if (u == null) return false;
    final path = u.path.toLowerCase();
    return (u.host.endsWith('zentrapay.com') && path.contains('/callback')) ||
        u.queryParameters.containsKey('trxref') ||
        (u.queryParameters.containsKey('tx_ref') &&
            u.queryParameters.containsKey('status'));
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (_isReturnUrl(request.url)) {
              if (mounted) Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            Center(child: CircularProgressIndicator(color: AppTheme.brand)),
        ],
      ),
    );
  }
}
