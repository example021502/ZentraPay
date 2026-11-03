import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zentrapay_application/core/afrilink_bank_connect_screen/BankLinkRequestDto.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/loading_overlay.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profile_data.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';

/// The AfriLink PUBLIC key from the app's `.env` (`AFRILINK_PUBLIC_KEY`, or the older
/// `AFRILINK_TEST_PK` name). Anything that is not a `pk_…` key is ignored: the `.env` is bundled
/// into the app as an asset, so a secret key (`sk_…`) placed there would ship to every device.
String? afriLinkPublicKey() {
  for (final name in const ['AFRILINK_PUBLIC_KEY', 'AFRILINK_TEST_PK']) {
    final value = (dotenv.maybeGet(name) ?? '').trim();
    if (value.startsWith('pk_')) return value;
  }
  return null;
}

/// Starts the "link a bank" flow from any button. Shows a clear message when the public key is
/// missing instead of opening a widget that cannot work. Resolves to the linked account or null.
Future<BankAccounts?> linkBankWithAfriLink(BuildContext context) async {
  final key = afriLinkPublicKey();
  if (key == null) {
    ZentraNotifier.error(
      'Bank linking unavailable',
      'Bank linking is not set up yet. Please try again later.',
    );
    debugPrint(
      'AfriLink: set AFRILINK_PUBLIC_KEY=pk_test_… in the app .env '
      '(the dashboard shows it next to the secret key; never put sk_… in the app).',
    );
    return null;
  }
  return AfriLinkBankConnectScreen.open(context, key);
}

/// Opens the AfriLink Connect widget (https://afrilink.io/docs) so the user links a bank
/// account WITHOUT typing an account number, name or bank credentials into ZentraPay.
///
/// Flow: widget (public key `pk_…`) -> user picks bank / logs in / consents inside AfriLink
/// -> the widget returns its token / session / account id / userId / institution -> we post exactly
/// that to `POST /api/zbanking/link` -> the backend completes the link with AfriLink (token +
/// public key) or reads the account back (account id + secret key) and saves it -> the bank
/// accounts are refreshed. Pops with the linked [BankAccounts] (or null when the user just closed it).
class AfriLinkBankConnectScreen extends StatefulWidget {
  /// AfriLink PUBLIC key (`pk_test_…` / `pk_live_…`). Secret keys (`sk_…`) are refused.
  final String publicKey;

  const AfriLinkBankConnectScreen({super.key, required this.publicKey});

  /// Opens the screen and resolves to the linked account, or null.
  static Future<BankAccounts?> open(BuildContext context, String publicKey) {
    return Navigator.of(context).push<BankAccounts>(
      MaterialPageRoute(
        builder: (_) => AfriLinkBankConnectScreen(publicKey: publicKey),
      ),
    );
  }

  @override
  State<AfriLinkBankConnectScreen> createState() =>
      _AfriLinkBankConnectScreenState();
}

class _AfriLinkBankConnectScreenState extends State<AfriLinkBankConnectScreen> {
  static const _channel = 'AfriLinkChannel';
  // The widget page is served as if it came from AfriLink itself so its own
  // requests (session, bank list) run from the origin it expects.
  static const _widgetOrigin = 'https://connect.afrilink.io';

  WebViewController? _controller;
  bool _saving = false;
  // Stops the app-wide loading overlay if AfriLink never reports that its widget is showing.
  Timer? _readyTimeout;
  String? _error;
  BankLinkRequestDto? _pending; // kept so "Try again" never repeats the bank login

  /// Display name / email the widget asks for (it requires them when no customer id is given).
  String _customerName = '';
  String _customerEmail = '';
  String _country = '';
  String _customerId = '';

  bool get _keyIsPublic => widget.publicKey.startsWith('pk_');

  @override
  void initState() {
    super.initState();
    if (!_keyIsPublic) {
      // Never hand a secret key to a WebView: it would be readable by the page and the device.
      _error =
          'Bank linking is not set up correctly (the app needs the AfriLink '
          'PUBLIC key, pk_…). Please contact support.';
      return;
    }
    if (kIsWeb) {
      _error = 'Linking a bank is only available in the mobile app.';
      return;
    }
    // The app's loading overlay covers the screen until AfriLink's widget is actually on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _error == null) {
        LoadingOverlay.show('Connecting to your bank…');
      }
    });
    _readyTimeout = Timer(const Duration(seconds: 20), _hideLoading);
    _start();
  }

  @override
  void dispose() {
    _readyTimeout?.cancel();
    // Hidden after the frame: dispose runs while the tree is locked, so the overlay cannot rebuild yet.
    WidgetsBinding.instance.addPostFrameCallback((_) => _hideLoading());
    super.dispose();
  }

  void _hideLoading() {
    _readyTimeout?.cancel();
    if (LoadingOverlay.isShowing) LoadingOverlay.hide();
  }

  /// Shows [message] on the error panel and removes the loading overlay.
  void _fail(String message) {
    _hideLoading();
    if (mounted) setState(() => _error = message);
  }

  Future<void> _start() async {
    try {
      final snapshot = await UserProfileRepository.instance.ensureLoaded();
      final user = snapshot?.user;
      _customerName = (user?.fullName ?? '').trim();
      _customerEmail = (user?.email ?? '').trim();
      _country = (user?.countryCode ?? '').trim();
      _customerId = (user?.userId ?? '').trim();
    } catch (_) {
      // The widget can still collect these itself if they are empty.
    }
    if (!mounted) return;
    _initializeWebView();
  }

  void _initializeWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.surface)
      ..setNavigationDelegate(
        NavigationDelegate(
          // The page finishing is NOT "ready": AfriLink's script still has to load and open its
          // widget. The page reports that itself ('ready' message); the overlay stays until then.
          onWebResourceError: (error) {
            // Sub-resource failures (fonts, trackers) are not fatal; only react to the main page.
            if (error.isForMainFrame ?? false) {
              _fail(
                'We could not reach the bank connection service. '
                'Check your internet connection and try again.',
              );
            }
          },
        ),
      )
      ..addJavaScriptChannel(_channel, onMessageReceived: _onWidgetMessage)
      ..loadHtmlString(_buildWidgetHtml(), baseUrl: _widgetOrigin);
    setState(() => _controller = controller);
  }

  /// The page that loads AfriLink's SDK and opens the widget straight away.
  String _buildWidgetHtml() {
    // Values go in as JSON string literals so a quote in a name can never break out of the script.
    String js(String value) => _jsonString(value);
    // The app's colours, so what we control (the page around the widget, and the theme options passed
    // to AfriLink) matches ZentraPay.
    String hex(Color c) =>
        '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    final surface = hex(AppTheme.surface);
    final text = hex(AppTheme.textBlack);
    final brand = hex(AppTheme.brand);
    final button = hex(AppTheme.buttonColor);
    final mode = AppTheme.isDark ? 'dark' : 'light';
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    :root { color-scheme: $mode; --zp-surface: $surface; --zp-text: $text; --zp-brand: $brand; }
    html, body { margin: 0; height: 100%; background: var(--zp-surface); color: var(--zp-text);
      font-family: -apple-system, 'Segoe UI', Roboto, sans-serif; accent-color: var(--zp-brand); }
    iframe { border: 0; }
  </style>
</head>
<body>
<script>
  function send(payload) { $_channel.postMessage(JSON.stringify(payload)); }

  var PUBLIC_KEY = ${js(widget.publicKey)};
  var CUSTOMER_NAME = ${js(_customerName)};
  var CUSTOMER_EMAIL = ${js(_customerEmail)};
  var CUSTOMER_ID = ${js(_customerId)};
  var started = false;

  // 1. The documented way: AfriLink's script, which opens the widget itself.
  function startSdk() {
    if (started) return;
    started = true;
    var afrilink = new AfriLinkConnect({
      publicKey: PUBLIC_KEY,
      customer: { name: CUSTOMER_NAME, email: CUSTOMER_EMAIL },
      // Colours of the app. Theme options the SDK does not know are ignored.
      theme: { mode: '$mode', primaryColor: '$brand', buttonColor: '$button', backgroundColor: '$surface', textColor: '$text' },
      onSuccess: function (data) { send({ type: 'success', data: data }); },
      onClose: function () { send({ type: 'close' }); },
      // The first event (WIDGET_OPENED ...) means the widget is on screen: drop the app's loading overlay.
      onEvent: function (event) {
        send({ type: 'event', name: 'sdk-event', detail: event });
        send({ type: 'ready' });
      },
      // Errors AfriLink's own steps raise (bank login, account verification ...) - logged so a failure can be traced
      onError: function (error) { send({ type: 'event', name: 'sdk-error', detail: error }); }
    });
    afrilink.open();
    // If the SDK never reports an event, do not leave the user behind the overlay.
    setTimeout(function () { send({ type: 'ready' }); }, 3000);
  }

  // 2. Fallback: the same widget page AfriLink serves on its main site, embedded. It reports back with
  //    postMessage({ source: 'afrilink-connect', type: 'SUCCESS' | 'CLOSE', data }). Used when the
  //    script host (connect.afrilink.io) is down or blocked, so linking does not depend on that one host.
  function startEmbedded() {
    if (started) return;
    started = true;
    window.addEventListener('message', function (event) {
      var d = event.data;
      if (typeof d === 'string') {
        try { d = JSON.parse(d); } catch (e) { return; }
      }
      if (!d || d.source !== 'afrilink-connect') return;
      send({ type: 'event', name: 'widget-' + d.type, detail: d });
      if (d.type === 'SUCCESS') {
        // keep anything the widget put next to the payload (session id, token ...)
        var data = (d.data && typeof d.data === 'object') ? d.data : {};
        ['sessionId', 'token', 'publicToken', 'authCode', 'code', 'userId', 'institution'].forEach(function (k) {
          if (d[k] != null && data[k] == null) data[k] = d[k];
        });
        send({ type: 'success', data: data });
      }
      else if (d.type === 'CLOSE') send({ type: 'close' });
    });
    var frame = document.createElement('iframe');
    frame.src = 'https://afrilink.io/widget?embed=true&key=' + encodeURIComponent(PUBLIC_KEY) +
      '&customerId=' + encodeURIComponent(CUSTOMER_ID || CUSTOMER_EMAIL || 'zentrapay_user');
    frame.style.cssText = 'border:0;width:100%;height:100vh;display:block;';
    frame.onload = function () { send({ type: 'ready' }); };
    document.body.appendChild(frame);
    send({ type: 'event', name: 'embedded-fallback' });
  }

  function loadSdk() {
    var script = document.createElement('script');
    script.src = 'https://connect.afrilink.io/sdk.js';
    var timer = setTimeout(function () {
      if (typeof AfriLinkConnect === 'undefined') startEmbedded();
    }, 8000);
    script.onload = function () {
      clearTimeout(timer);
      if (typeof AfriLinkConnect === 'undefined') startEmbedded(); else startSdk();
    };
    script.onerror = function () { clearTimeout(timer); startEmbedded(); };
    document.head.appendChild(script);
  }
  window.onload = loadSdk;
</script>
</body>
</html>
''';
  }

  static String _jsonString(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', '')
        .replaceAll('<', r'<');
    return '"$escaped"';
  }

  void _onWidgetMessage(JavaScriptMessage message) {
    Map<String, dynamic> payload;
    try {
      payload = BankLinkRequestDto.decode(message.message);
    } catch (_) {
      return; // not ours
    }
    switch (payload['type']) {
      case 'success':
        final data = payload['data'];
        final dto = data is Map
            ? BankLinkRequestDto.fromWidgetData(
                Map<String, dynamic>.from(data),
                country: _country,
              )
            : null;
        if (dto == null) {
          _fail('The bank connection did not complete.');
          return;
        }
        _submit(dto);
      case 'close':
        if (!_saving && mounted && _pending == null) {
          Navigator.of(context).pop();
        }
      case 'ready':
        _hideLoading();
      case 'event':
        // Debug builds only: shows exactly what AfriLink's widget reported (never printed in release)
        if (kDebugMode) {
          debugPrint('AfriLink: ${payload['name']} ${payload['detail'] ?? ''}');
        }
      case 'error':
        _fail(
          'We could not load the bank connection service. '
          'Please try again in a moment.',
        );
    }
  }

  /// Sends the account id to the backend, which verifies it with AfriLink and saves the link.
  Future<void> _submit(BankLinkRequestDto dto) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
      _pending = dto;
    });
    LoadingOverlay.show('Linking your account…');
    try {
      final linked = await BankAccountsRepository.instance.linkBank(dto);
      _hideLoading();
      if (!mounted) return;
      ZentraNotifier.success(
        'Bank linked',
        '${linked.displayName} is now connected to your ZentraPay account.',
      );
      Navigator.of(context).pop(linked);
    } catch (e) {
      _hideLoading();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = errorMessage(
          e,
          fallback: 'We could not link this bank account. Please try again.',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Connect bank account'),
        backgroundColor: AppTheme.headerPink,
        foregroundColor: AppTheme.primaryWhite,
        elevation: 0,
      ),
      // Loading ("Connecting to your bank…" / "Linking your account…") is the app-wide LoadingOverlay.
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_error != null && !_saving) _errorPanel(_error!),
        ],
      ),
    );
  }

  Widget _errorPanel(String message) {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppTheme.errorRed),
            const SizedBox(height: AppTheme.spacingMd),
            Text(message, textAlign: TextAlign.center, style: AppTheme.bodyMedium),
            const SizedBox(height: AppTheme.spacingLg),
            if (_pending != null)
              ElevatedButton(
                onPressed: () => _submit(_pending!),
                child: const Text('Try again'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
