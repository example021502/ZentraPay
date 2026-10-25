import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/Settings/repository/credential_service.dart';

String _noun(CredentialKind kind) =>
    kind == CredentialKind.pin ? 'PIN' : 'password';

/// Checks a new PIN / password; returns an error message or null when fine.
String? _validateNew(CredentialKind kind, String value) {
  if (kind == CredentialKind.pin) {
    return RegExp(r'^\d{4}$').hasMatch(value)
        ? null
        : 'A PIN is exactly 4 digits';
  }
  if (value.length < 8 || value.length > 32) {
    return 'A password needs 8 to 32 characters';
  }
  return null;
}

InputDecoration _fieldDecoration(
  CredentialKind kind,
  String label, {
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    counterText: '',
    prefixIcon: Icon(
      kind == CredentialKind.pin ? Icons.pin_outlined : Icons.lock_outline,
    ),
    suffixIcon: suffix,
  );
}

/// A secret input: dots, digits-only for a PIN, show/hide for a password.
class _SecretField extends StatefulWidget {
  final CredentialKind kind;
  final String label;
  final TextEditingController controller;
  final bool enabled;

  const _SecretField({
    required this.kind,
    required this.label,
    required this.controller,
    this.enabled = true,
  });

  @override
  State<_SecretField> createState() => _SecretFieldState();
}

class _SecretFieldState extends State<_SecretField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    final isPin = widget.kind == CredentialKind.pin;
    return TextField(
      controller: widget.controller,
      enabled: widget.enabled,
      obscureText: _hidden,
      keyboardType: isPin
          ? TextInputType.number
          : TextInputType.visiblePassword,
      maxLength: isPin ? 4 : 32,
      inputFormatters: isPin ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: _fieldDecoration(
        widget.kind,
        widget.label,
        suffix: IconButton(
          icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Change (current value required)
// ---------------------------------------------------------------------------

/// "Change PIN" / "Change password": the previous value must be entered
/// first. "Forgot?" opens the recovery overlay.
Future<void> showChangeCredentialSheet(
  BuildContext context,
  CredentialKind kind,
) {
  return showAppOverlaySheet<void>(
    context: context,
    minHeightFraction: 0.55,
    maxWidth: 560,
    builder: (_) => _ChangeCredentialBody(kind: kind),
  );
}

class _ChangeCredentialBody extends StatefulWidget {
  final CredentialKind kind;

  const _ChangeCredentialBody({required this.kind});

  @override
  State<_ChangeCredentialBody> createState() => _ChangeCredentialBodyState();
}

class _ChangeCredentialBodyState extends State<_ChangeCredentialBody> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final kind = widget.kind;
    final noun = _noun(kind);
    if (_current.text.isEmpty) {
      setState(() => _error = 'Enter your current $noun');
      return;
    }
    final problem = _validateNew(kind, _next.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'The new $noun and its confirmation differ');
      return;
    }
    if (_next.text == _current.text) {
      setState(() => _error = 'Choose a $noun different from the current one');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await CredentialService.change(
        kind,
        current: _current.text,
        next: _next.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ZentraNotifier.success(
        kind == CredentialKind.pin ? 'PIN changed' : 'Password changed',
        'Your new $noun is active.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorMessage(
          e,
          fallback: "We couldn't change your $noun. Please try again.",
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final noun = _noun(kind);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingSm,
        AppTheme.spacingLg,
        AppTheme.spacingLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Change $noun', style: AppTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(
            'For your security, enter your current $noun first.',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          _SecretField(
            kind: kind,
            label: 'Current $noun',
            controller: _current,
            enabled: !_busy,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _busy
                  ? null
                  : () => showForgotCredentialOverlay(context, kind),
              child: Text('Forgot $noun?'),
            ),
          ),
          _SecretField(
            kind: kind,
            label: 'New $noun',
            controller: _next,
            enabled: !_busy,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _SecretField(
            kind: kind,
            label: 'Confirm new $noun',
            controller: _confirm,
            enabled: !_busy,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _error!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
            ),
          ],
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Update $noun',
              loading: _busy,
              onPressed: _submit,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Forgot (emailed code -> new value)
// ---------------------------------------------------------------------------

/// The recovery overlay. It cannot be dismissed by tapping outside or the
/// system back button: the only ways out are the Close button (after a
/// confirmation) or finishing the reset.
///
/// Steps: a code is emailed to the registered address -> the user pastes it and
/// presses Done (a loader shows while the server checks it) -> only when the
/// server accepts it are the new PIN / password fields shown -> Reset.
Future<void> showForgotCredentialOverlay(
  BuildContext context,
  CredentialKind kind,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Reset ${_noun(kind)}',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, _, _) => PopScope(
      canPop: false,
      child: SafeArea(
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: _ForgotCredentialCard(kind: kind),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(animation),
        child: child,
      ),
    ),
  );
}

enum _ForgotStep { sending, enterCode, newValue, done }

class _ForgotCredentialCard extends StatefulWidget {
  final CredentialKind kind;

  const _ForgotCredentialCard({required this.kind});

  @override
  State<_ForgotCredentialCard> createState() => _ForgotCredentialCardState();
}

class _ForgotCredentialCardState extends State<_ForgotCredentialCard> {
  final _code = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  _ForgotStep _step = _ForgotStep.sending;
  bool _busy = false;
  String _emailHint = '';
  String? _resetToken;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  @override
  void dispose() {
    _code.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    setState(() {
      _step = _ForgotStep.sending;
      _error = null;
    });
    try {
      final hint = await CredentialService.requestReset(widget.kind);
      if (!mounted) return;
      setState(() {
        _emailHint = hint;
        _step = _ForgotStep.enterCode;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _ForgotStep.enterCode;
        _error = errorMessage(
          e,
          fallback: "We couldn't send the code. Please try again.",
        );
      });
    }
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) return;
    setState(() {
      _code.text = text;
      _error = null;
    });
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Paste the code from your email');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final token = await CredentialService.verifyCode(widget.kind, code);
      if (!mounted) return;
      setState(() {
        _resetToken = token;
        _step = _ForgotStep.newValue;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorMessage(
          e,
          fallback: "That code didn't work. Check it and try again.",
        );
      });
    }
  }

  Future<void> _reset() async {
    final kind = widget.kind;
    final noun = _noun(kind);
    final problem = _validateNew(kind, _next.text);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'The new $noun and its confirmation differ');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await CredentialService.reset(
        kind,
        resetToken: _resetToken!,
        next: _next.text,
      );
      if (!mounted) return;
      setState(() {
        _step = _ForgotStep.done;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = errorMessage(
          e,
          fallback: "We couldn't reset your $noun. Please try again.",
        );
      });
    }
  }

  /// Close asks first: leaving mid-way throws the emailed code away.
  Future<void> _close() async {
    if (_step == _ForgotStep.done) {
      Navigator.pop(context);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusXl),
        ),
        title: Text('Stop resetting your ${_noun(widget.kind)}?'),
        content: const Text(
          'The code we emailed will no longer be needed, and nothing will be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, close'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final noun = _noun(widget.kind);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusXxl),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Reset $noun', style: AppTheme.headlineMedium),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : _close,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Close'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ..._stepContent(noun),
          ],
        ),
      ),
    );
  }

  List<Widget> _stepContent(String noun) {
    switch (_step) {
      case _ForgotStep.sending:
        return [
          const SizedBox(height: AppTheme.spacingLg),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: AppTheme.spacingMd),
          Center(
            child: Text(
              'Sending a code to your email…',
              style: AppTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
        ];
      case _ForgotStep.enterCode:
        return [
          Text(
            _emailHint.isEmpty
                ? 'Paste the code we emailed to your registered address.'
                : 'We emailed a code to $_emailHint. Copy it from the email and paste it here.',
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          TextField(
            controller: _code,
            enabled: !_busy,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              labelText: 'Code from your email',
              prefixIcon: const Icon(Icons.mark_email_read_outlined),
              suffixIcon: TextButton(
                onPressed: _busy ? null : _paste,
                child: const Text('Paste'),
              ),
            ),
          ),
          ..._errorText(),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Done',
              loading: _busy,
              onPressed: _verify,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _busy ? null : _sendCode,
              child: const Text('Send a new code'),
            ),
          ),
        ];
      case _ForgotStep.newValue:
        return [
          Row(
            children: [
              const Icon(Icons.verified, color: AppTheme.successGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Code confirmed. Choose your new $noun.',
                  style: AppTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _SecretField(
            kind: widget.kind,
            label: 'New $noun',
            controller: _next,
            enabled: !_busy,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _SecretField(
            kind: widget.kind,
            label: 'Confirm new $noun',
            controller: _confirm,
            enabled: !_busy,
          ),
          ..._errorText(),
          const SizedBox(height: AppTheme.spacingMd),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Reset',
              loading: _busy,
              onPressed: _reset,
            ),
          ),
        ];
      case _ForgotStep.done:
        return [
          const SizedBox(height: AppTheme.spacingSm),
          const Center(
            child: Icon(
              Icons.check_circle,
              color: AppTheme.successGreen,
              size: 56,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Center(
            child: Text(
              'Your $noun has been reset.',
              style: AppTheme.labelLarge,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ];
    }
  }

  List<Widget> _errorText() => _error == null
      ? const []
      : [
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            _error!,
            style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
          ),
        ];
}
