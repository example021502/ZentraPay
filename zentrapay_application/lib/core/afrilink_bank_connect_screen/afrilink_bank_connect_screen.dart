import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zentrapay_application/core/afrilink_bank_connect_screen/bank_link_request_dto.dart';
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
  // True once AfriLink's widget reported that it is on screen.
  bool _ready = false;
  // The error on screen is "the widget did not open" (Try again reloads it) rather than "linking failed".
  bool _loadFailed = false;
  // Gives up waiting if AfriLink never reports that its widget is showing.
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
    _armReadyTimeout();
    _start();
  }

  /// If AfriLink's widget has not shown up after this long, say so and offer "Try again" instead of
  /// leaving a blank page (the page itself already switches to its embedded fallback after ~3-6 s).
  void _armReadyTimeout() {
    _readyTimeout?.cancel();
    _readyTimeout = Timer(const Duration(seconds: 18), () {
      if (_ready || !mounted || _saving) return;
      _loadFailed = true;
      _fail(
        'The bank connection is taking too long to open. '
        'Check your internet connection and try again.',
      );
    });
  }

  /// "Try again" after the widget failed to open: builds a fresh WebView and starts over.
  void _retryLoad() {
    setState(() {
      _error = null;
      _loadFailed = false;
      _ready = false;
      _controller = null;
    });
    LoadingOverlay.show('Connecting to your bank…');
    _armReadyTimeout();
    _initializeWebView();
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
      // Use the profile already in memory. Only when it is not loaded yet is it waited for, and only
      // briefly: the widget can ask for the name / email itself, so it must never be held up by the profile.
      var snapshot = UserProfileRepository.instance.data;
      snapshot ??= await UserProfileRepository.instance.ensureLoaded().timeout(
        const Duration(milliseconds: 1500),
      );
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
              _loadFailed = true;
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
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
  <!-- Open the connections to AfriLink's hosts while the page is still being set up -->
  <link rel="preconnect" href="https://connect.afrilink.io" crossorigin>
  <link rel="preconnect" href="https://afrilink.io" crossorigin>
  <style>
    :root { color-scheme: $mode; --zp-surface: $surface; --zp-text: $text; --zp-brand: $brand; }
    html, body { margin: 0; padding: 0; width: 100%; height: 100%; overflow: hidden; background: var(--zp-surface);
      color: var(--zp-text); font-family: -apple-system, 'Segoe UI', Roboto, sans-serif; accent-color: var(--zp-brand);
      -webkit-tap-highlight-color: transparent; }
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
  var mode = null;          // 'sdk' | 'embedded' - which way the widget was started
  var overlaySeen = false;  // the SDK put its overlay on the page

  // The SDK builds its overlay for a desktop page (a dimmed backdrop and a card). On a phone it must
  // simply fill the screen: whatever fixed-position element or iframe it adds is stretched to the viewport.
  function fill(el) {
    if (!el || el.nodeType !== 1 || el.id === 'zp-embedded') return false;
    var tag = el.tagName;
    if (tag === 'SCRIPT' || tag === 'STYLE' || tag === 'LINK' || tag === 'META') return false;
    var fixed = false;
    try { fixed = getComputedStyle(el).position === 'fixed'; } catch (e) {}
    if (!fixed && tag !== 'IFRAME') return false;
    var s = el.style;
    ['top', 'right', 'bottom', 'left'].forEach(function (p) { s.setProperty(p, '0', 'important'); });
    s.setProperty('position', 'fixed', 'important');
    s.setProperty('width', '100%', 'important');
    s.setProperty('height', '100%', 'important');
    s.setProperty('max-width', 'none', 'important');
    s.setProperty('max-height', 'none', 'important');
    s.setProperty('margin', '0', 'important');
    s.setProperty('transform', 'none', 'important');
    s.setProperty('border-radius', '0', 'important');
    s.setProperty('border', '0', 'important');
    return true;
  }
  new MutationObserver(function (records) {
    records.forEach(function (r) {
      r.addedNodes.forEach(function (n) {
        if (fill(n) && mode === 'sdk' && !overlaySeen) {
          overlaySeen = true;
          send({ type: 'event', name: 'sdk-overlay-added' });
          send({ type: 'ready' });
        }
      });
    });
  }).observe(document.body, { childList: true });

  // 1. The documented way: AfriLink's script, which opens the widget itself.
  function startSdk() {
    if (mode) return;
    mode = 'sdk';
    try {
      var afrilink = new AfriLinkConnect({
        publicKey: PUBLIC_KEY,
        customer: { name: CUSTOMER_NAME, email: CUSTOMER_EMAIL },
        // Colours of the app. Theme options the SDK does not know are ignored.
        theme: { mode: '$mode', primaryColor: '$brand', buttonColor: '$button', backgroundColor: '$surface', textColor: '$text' },
        onSuccess: function (data) { send({ type: 'success', data: data }); },
        onClose: function () { send({ type: 'close' }); },
        // The first event (WIDGET_OPENED ...) means the widget is on screen: drop the app's loading overlay.
        onEvent: function (event) {
          overlaySeen = true;
          send({ type: 'event', name: 'sdk-event', detail: event });
          send({ type: 'ready' });
        },
        // Errors AfriLink's own steps raise (bank login, account verification ...) - logged so a failure can be traced
        onError: function (error) { send({ type: 'event', name: 'sdk-error', detail: error }); }
      });
      afrilink.open();
    } catch (e) {
      // The SDK loaded but would not open: use the embedded widget instead of leaving a blank page
      send({ type: 'event', name: 'sdk-threw', detail: String(e) });
      mode = null;
      startEmbedded();
      return;
    }
    // If the SDK shows nothing at all (no event and no overlay) within 6 s, switch to the embedded widget.
    setTimeout(function () {
      if (mode === 'sdk' && !overlaySeen) {
        send({ type: 'event', name: 'sdk-silent' });
        mode = null;
        startEmbedded();
      }
    }, 6000);
  }

  // 2. Fallback: the same widget page AfriLink serves on its main site, embedded. It reports back with
  //    postMessage({ source: 'afrilink-connect', type: 'SUCCESS' | 'CLOSE', data }). Used when the
  //    script host (connect.afrilink.io) is slow, down or blocked, so linking does not depend on that one host.
  function startEmbedded() {
    if (mode) return;
    mode = 'embedded';
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
    frame.id = 'zp-embedded';
    frame.src = 'https://afrilink.io/widget?embed=true&key=' + encodeURIComponent(PUBLIC_KEY) +
      '&customerId=' + encodeURIComponent(CUSTOMER_ID || CUSTOMER_EMAIL || 'zentrapay_user');
    frame.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;border:0;width:100%;height:100%;display:block;background:' +
      getComputedStyle(document.documentElement).getPropertyValue('--zp-surface');
    frame.onload = function () { send({ type: 'ready' }); };
    document.body.appendChild(frame);
    send({ type: 'event', name: 'embedded-fallback' });
  }

  // Load AfriLink's script right away (not after the page's load event, which waits for everything else).
  // The script host is the slow part: if it has not answered in 3 s the embedded widget is used instead of waiting.
  var sdkTimer = setTimeout(function () {
    if (typeof AfriLinkConnect === 'undefined') {
      send({ type: 'event', name: 'sdk-script-slow' });
      startEmbedded();
    }
  }, 3000);
  var script = document.createElement('script');
  script.src = 'https://connect.afrilink.io/sdk.js';
  script.onload = function () {
    clearTimeout(sdkTimer);
    // The script can arrive after the 3 s fallback already started the embedded widget: then it is not used
    if (typeof AfriLinkConnect === 'undefined') startEmbedded(); else startSdk();
  };
  script.onerror = function () { clearTimeout(sdkTimer); startEmbedded(); };
  document.head.appendChild(script);
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
        _ready = true;
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
      // The widget is AfriLink's own page: it gets the whole area under the app bar, kept clear of the
      // phone's bottom gesture bar / notch so its buttons are never covered.
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            if (_controller != null) WebViewWidget(controller: _controller!),
            if (_error != null && !_saving) _errorPanel(_error!),
          ],
        ),
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
              )
            else if (_loadFailed)
              ElevatedButton(
                onPressed: _retryLoad,
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
