import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';

/// Thrown when a scanned code parses as ZentraPay but still can't start a
/// payment (the receiver identity is too incomplete for the backend).
class QrScanException implements Exception {
  const QrScanException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Result handed back to the Pay section once a code has been scanned and
/// resolved: the `appUser` map the payments endpoint expects, plus the
/// currency the receiver's QR account is denominated in (used to preselect
/// the currency on the Enter Amount sheet).
class ScannedPaymentTarget {
  const ScannedPaymentTarget({
    required this.recipient,
    required this.receiveCurrency,
  });

  /// Shape expected by the backend's
  /// `InitializePaymentRequestDTO.AppUserDetails`:
  /// `{userId, name, zentag, countryCode, phoneNumber, type}`.
  final Map<String, dynamic> recipient;

  /// Currency from the scanned QR (`currency` param) — empty when unknown.
  final String receiveCurrency;
}

/// The `zentrapay://pay?...` payload minted by the Receive sheet, parsed and
/// validated against what `POST /api/payments/initialize` needs.
class QrPaymentPayload {
  const QrPaymentPayload({
    required this.userId,
    required this.zentag,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.countryCode,
    required this.userType,
    required this.currencyCode,
    required this.accountId,
  });

  final String userId;
  final String zentag;
  final String name;
  final String email;
  final String phoneNumber;
  final String countryCode;
  final String userType;
  final String currencyCode;
  final String accountId;

  /// Tolerant parser: accepts the full deep link
  /// (`zentrapay://pay?zentag=…`), a bare query string (`zentag=…`) and a
  /// plain zentag text. Returns null for anything that isn't a ZentraPay
  /// payment code (a foreign QR must simply keep scanning, not crash).
  static QrPaymentPayload? tryParse(String raw) {
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    Map<String, String> params;
    final Uri? uri = Uri.tryParse(trimmed);
    if (uri != null && uri.scheme == 'zentrapay' && uri.hasQuery) {
      params = uri.queryParameters;
    } else if (trimmed.contains('=')) {
      final int qIndex = trimmed.indexOf('?');
      try {
        params = Uri.splitQueryString(
          qIndex == -1 ? trimmed : trimmed.substring(qIndex + 1),
        );
      } on FormatException {
        return null;
      }
    } else if (trimmed.contains('@')) {
      // Bare zentag (e.g. "0240000000_GHS@zentrapay") — the minimum routing
      // key the backend's INTERNAL transfer resolves the receiver wallet with.
      params = {'zentag': trimmed};
    } else {
      return null;
    }

    final String zentag = params['zentag']?.trim() ?? '';
    final String phoneNumber = params['phoneNumber']?.trim() ?? '';
    // Without at least one routing identifier there is nothing for
    // PaymentsInitializeService#_resolverReceiver to find the receiver with.
    if (zentag.isEmpty && phoneNumber.isEmpty) return null;

    return QrPaymentPayload(
      userId: params['userId']?.trim() ?? '',
      zentag: zentag,
      name: params['name']?.trim() ?? '',
      email: params['email']?.trim() ?? '',
      phoneNumber: phoneNumber,
      countryCode: params['countryCode']?.trim() ?? '',
      userType: params['userType']?.trim() ?? '',
      currencyCode: params['currency']?.trim() ?? '',
      accountId: params['accountId']?.trim() ?? '',
    );
  }

  bool get _needsLookup =>
      userId.isEmpty ||
      name.isEmpty ||
      countryCode.isEmpty ||
      phoneNumber.isEmpty ||
      zentag.isEmpty ||
      userType.isEmpty;

  /// Turns the parsed payload into the payment recipient, falling back to a
  /// contact search when the code itself doesn't carry every field (codes
  /// minted before `userId` existed, plain-zentag tags, …). Throws
  /// [QrScanException] when the receiver still can't be identified.
  Future<ScannedPaymentTarget> toPaymentTarget() async {
    String userId = this.userId;
    String name = this.name;
    String phoneNumber = this.phoneNumber;
    String countryCode = this.countryCode;
    String userType = this.userType;
    String zentag = this.zentag;

    if (_needsLookup) {
      try {
        final String query = zentag.isNotEmpty ? zentag : phoneNumber;
        final ContactSearchResult result = await SearchRepository.search(query);
        SearchAppUser? match;
        for (final SearchAppUser u in result.appUsers) {
          final bool byZentag = zentag.isNotEmpty && u.zentag == zentag;
          final bool byPhone =
              phoneNumber.isNotEmpty && u.phoneNumber == phoneNumber;
          if (byZentag || byPhone) {
            match = u;
            break;
          }
        }
        if (match != null) {
          userId = userId.isNotEmpty ? userId : match.userId;
          name = name.isNotEmpty ? name : match.fullName;
          phoneNumber = phoneNumber.isNotEmpty
              ? phoneNumber
              : match.phoneNumber;
          countryCode = countryCode.isNotEmpty
              ? countryCode
              : match.countryCode;
          zentag = zentag.isNotEmpty ? zentag : match.zentag;
          userType = userType.isNotEmpty ? userType : match.userType;
        }
      } catch (_) {
        // Search is best-effort (offline, cross-country, not an app user) —
        // fall through and validate against whatever the QR itself carried.
      }
    }

    // Minimum the backend needs to move money: a receiver name for the
    // transaction/notification text, a country, a user type, and at least one
    // routing identifier (zentag, else phone number).
    if (name.isEmpty) {
      throw const QrScanException(
        "This QR code is missing the receiver's name.",
      );
    }
    if (countryCode.isEmpty) {
      throw const QrScanException(
        "This QR code is missing the receiver's country.",
      );
    }
    if (zentag.isEmpty && phoneNumber.isEmpty) {
      throw const QrScanException(
        "This QR code has no zentag or phone number to pay.",
      );
    }

    return ScannedPaymentTarget(
      recipient: {
        "userId": userId,
        "name": name,
        "zentag": zentag,
        "accountNumber": "",
        "phoneNumber": phoneNumber,
        "countryCode": countryCode,
        "type": userType.isNotEmpty ? userType : "APP_USER",
      },
      receiveCurrency: currencyCode,
    );
  }
}

/// Full-screen camera scanner for the Pay section's Scan button.
/// Pops with a resolved [ScannedPaymentTarget] on success, or null on cancel.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  static Future<ScannedPaymentTarget?> show(BuildContext context) {
    return Navigator.of(context).push<ScannedPaymentTarget>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const QrScanScreen(),
      ),
    );
  }

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  late final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Guards against overlapping resolutions while a scan is being looked up.
  bool _resolving = false;

  /// Last rejected code/message — keeps the toast from re-firing on every
  /// frame while the camera keeps pointing at the same unusable code.
  String? _lastRejected;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_resolving || capture.barcodes.isEmpty) return;
    final String? raw = capture.barcodes.first.rawValue;
    if (raw == null || raw.trim().isEmpty) return;

    final QrPaymentPayload? payload = QrPaymentPayload.tryParse(raw);
    if (payload == null) {
      _reject(
        raw,
        "Not a ZentraPay QR code",
        "Point the camera at a receive QR code from ZentraPay.",
      );
      return;
    }

    setState(() => _resolving = true);
    try {
      final ScannedPaymentTarget target = await payload.toPaymentTarget();
      if (!mounted) return;
      Navigator.of(context).pop(target);
    } on QrScanException catch (e) {
      if (!mounted) return;
      setState(() => _resolving = false);
      _reject(e.message, "Can't start payment", e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolving = false);
      _reject(
        raw,
        "Couldn't read that code",
        "Please try again with the code fully inside the frame.",
      );
    }
  }

  void _reject(String key, String title, String message) {
    if (_lastRejected == key) return;
    _lastRejected = key;
    ZentraNotifier.error(title, message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Text(
                  error.errorCode == MobileScannerErrorCode.permissionDenied
                      ? "Camera permission is required to scan QR codes. "
                            "Enable it in your device settings."
                      : "Could not start the camera. Please try again.",
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.primaryWhite,
                  ),
                ),
              ),
            ),
          ),

          // Dimmed viewfinder frame (pure decoration — taps pass through).
          const IgnorePointer(child: _ScanFrameOverlay()),

          // Top bar: close + torch.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd,
                vertical: AppTheme.spacingSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleAction(
                    icon: Icons.close,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _CircleAction(
                    icon: Icons.flash_on,
                    onTap: () => _controller.toggleTorch(),
                  ),
                ],
              ),
            ),
          ),

          // Resolving spinner over the frame.
          if (_resolving)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: const CircularProgressIndicator(
                color: AppTheme.primaryPink,
              ),
            ),

          // Hint.
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: AppTheme.spacingXl,
                left: AppTheme.spacingLg,
                right: AppTheme.spacingLg,
              ),
              child: Text(
                _resolving
                    ? "Starting payment…"
                    : "Scan the receiver's QR code to pay them instantly",
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.primaryWhite,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular glass button used on the scanner chrome.
class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          child: Icon(icon, color: AppTheme.textBlack, size: 24),
        ),
      ),
    );
  }
}

/// The screen dimmed around a clear, rounded scanning window.
class _ScanFrameOverlay extends StatelessWidget {
  const _ScanFrameOverlay();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ScanFramePainter());
  }
}

class _ScanFramePainter extends CustomPainter {
  static const double _window = 260;
  static const double _radius = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final double left = (size.width - _window) / 2;
    final double top = (size.height - _window) / 2;
    final RRect window = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, _window, _window),
      const Radius.circular(_radius),
    );

    // The screen is dimmed everywhere except a clear, rounded scanning window
    // (no border line around it), so the camera preview stays visible inside.
    final Path dimmed = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRRect(window),
    );
    canvas.drawPath(
      dimmed,
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
