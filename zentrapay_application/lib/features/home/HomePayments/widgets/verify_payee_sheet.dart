import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Common/account_number_rules.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';

/// Which kind of external account is being paid.
enum PayeeKind { bank, mobileMoney }

/// A bank / mobile-money account the payment providers have been asked about.
/// [recipient] is the object the payments endpoint expects under `bank` or
/// `mobileMoney`; [displayName] is what the sender sees on the PIN sheet.
class VerifiedPayee {
  final PayeeKind kind;
  final String displayName;
  final String destinationName;
  final String accountNumber;
  final String countryCode;
  final bool nameConfirmed;
  final Map<String, dynamic> recipient;

  const VerifiedPayee({
    required this.kind,
    required this.displayName,
    required this.destinationName,
    required this.accountNumber,
    required this.countryCode,
    required this.nameConfirmed,
    required this.recipient,
  });
}

/// Asks for an account number and the account holder's first and last name
/// (bank) or a phone number (mobile money), checks it with the payment
/// providers and shows who owns it. Resolves to the confirmed payee only when
/// the sender taps "Continue" - nothing is sent before then, and no amount or
/// PIN is asked for until the account has been verified.
///
/// The number is held to the length real accounts in that country have, and
/// for a bank the names typed must match the name the bank holds.
Future<VerifiedPayee?> showVerifyPayeeSheet({
  required BuildContext context,
  Banks? bank,
  MobileMoneyProvider? mobileMoney,
}) {
  assert((bank == null) != (mobileMoney == null));
  return showAppOverlaySheet<VerifiedPayee>(
    context: context,
    minHeightFraction: 0.65,
    maxWidth: 560,
    builder: (_) => _VerifyPayeeBody(bank: bank, mobileMoney: mobileMoney),
  );
}

class _VerifyPayeeBody extends StatefulWidget {
  final Banks? bank;
  final MobileMoneyProvider? mobileMoney;

  const _VerifyPayeeBody({this.bank, this.mobileMoney});

  @override
  State<_VerifyPayeeBody> createState() => _VerifyPayeeBodyState();
}

class _VerifyPayeeBodyState extends State<_VerifyPayeeBody> {
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  bool _checking = false;
  String? _error;
  VerifiedAccount? _verified;

  /// True when the bank's name for the account does not match the names typed.

  bool get _isBank => widget.bank != null;
  String get _destinationName =>
      _isBank ? widget.bank!.bankName : widget.mobileMoney!.name;
  String get _countryCode =>
      _isBank ? widget.bank!.countryCode : widget.mobileMoney!.countryCode;

  AccountNumberRule get _rule => _isBank
      ? AccountNumberRule.forBank(_countryCode)
      : AccountNumberRule.mobileMoney;

  String get _noun => _isBank ? 'account number' : 'mobile money number';

  /// What is sent to the backend: no spaces or dashes.
  String get _number => _numberController.text.replaceAll(RegExp(r'[\s-]'), '');

  /// Digits only, for the length check (drops a leading + as well).
  String get _digits => _number.replaceAll(RegExp(r'\D'), '');

  @override
  void dispose() {
    _numberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  String? _validate() {
    final numberProblem = _rule.validate(_digits, noun: _noun);
    if (numberProblem != null) return numberProblem;
    return null;
  }

  void _clearResult() {
    if (_verified != null || _error != null) {
      _verified = null;
      _error = null;
    }
  }

  Future<void> _check() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _checking = true;
      _error = null;
      _verified = null;
    });
    try {
      final result = await SearchRepository.verifyAccount(
        destinationType: _isBank ? 'BANK' : 'MOBILE_MONEY',
        destinationId: _isBank
            ? widget.bank!.bankId
            : widget.mobileMoney!.providerId,
        destinationCode: _isBank
            ? widget.bank!.bankCode
            : widget.mobileMoney!.providerCode,
        accountNumber: _number,
        countryCode: _countryCode,
      );
      if (!mounted) return;
      setState(() {
        _accountNameController.text = result.accountName;
        _verified = result.verified ? result : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _messageOf(e));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  String _messageOf(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final message = (e.response!.data as Map)['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return "We could not check this account right now. Please try again.";
  }

  void _continue() {
    final verified = _verified;
    if (verified == null) return;
    final number = _number;
    final name = verified.accountName.trim();
    final Map<String, dynamic> recipient;
    if (_isBank) {
      final bank = widget.bank!;
      recipient = {
        'bankId': bank.bankId,
        'bankName': bank.bankName,
        'bankCode': bank.bankCode,
        'accountNumber': number,
        'accountName': name,
        'countryCode': bank.countryCode,
      };
    } else {
      final momo = widget.mobileMoney!;
      recipient = {
        'providerId': momo.providerId,
        'providerName': momo.name,
        'providerCode': momo.providerCode,
        'phoneNumber': number,
        if (name.isNotEmpty) 'accountName': name,
        'countryCode': momo.countryCode,
      };
    }
    Navigator.pop(
      context,
      VerifiedPayee(
        kind: _isBank ? PayeeKind.bank : PayeeKind.mobileMoney,
        displayName: name.isNotEmpty ? name : "$_destinationName · $number",
        destinationName: _destinationName,
        accountNumber: number,
        countryCode: _countryCode,
        nameConfirmed: verified.verified && name.isNotEmpty,
        recipient: recipient,
      ),
    );
  }

  Widget _nameField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      enabled: false,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s'\-]")),
        LengthLimitingTextInputFormatter(40),
      ],
      onChanged: (_) => setState(_clearResult),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.person_outline),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verified = _verified;
    final rule = _rule;
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Icon(
                  _isBank
                      ? Icons.account_balance_outlined
                      : Icons.phone_android_outlined,
                  color: AppTheme.textBlack,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _destinationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.headlineSmall,
                    ),
                    Text(
                      _isBank ? "Bank transfer" : "Mobile money",
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          TextField(
            controller: _numberController,
            enabled: !_checking,
            keyboardType: _isBank ? TextInputType.number : TextInputType.phone,
            textInputAction: _isBank
                ? TextInputAction.next
                : TextInputAction.done,
            inputFormatters: [
              if (_isBank)
                FilteringTextInputFormatter.digitsOnly
              else
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
              LengthLimitingTextInputFormatter(_isBank ? rule.max : 18),
            ],
            onChanged: (_) => setState(_clearResult),
            onSubmitted: (_) {
              if (!_isBank) _check();
            },
            decoration: InputDecoration(
              labelText: _isBank ? "Account number" : "Mobile money number",
              helperText: '${_digits.length} entered · ${rule.label}',
              prefixIcon: Icon(
                _isBank ? Icons.pin_outlined : Icons.phone_outlined,
              ),
            ),
          ),
          if (_isBank) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _nameField(_accountNameController, "Account holder's name"),
            const SizedBox(height: AppTheme.spacingMd),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          if (_error != null)
            _notice(
              icon: Icons.error_outline,
              color: AppTheme.errorRed,
              text: _error!,
            ),

          if (verified != null) _resultCard(verified),
          const SizedBox(height: AppTheme.spacingLg),
          if (verified == null)
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: "Verify account",
                loading: _checking,
                onPressed: _check,
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(label: "Continue", onPressed: _continue),
            ),
        ],
      ),
    );
  }

  Widget _resultCard(VerifiedAccount verified) {
    final confirmed = verified.verified && verified.accountName.isNotEmpty;
    if (!confirmed) {
      return _notice(
        icon: Icons.info_outline,
        color: AppTheme.warningOrange,
        text:
            "$_destinationName does not share the wallet owner's name, so we "
            "could not confirm it. Check the number carefully before you continue.",
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified, color: AppTheme.successGreen),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(verified.accountName, style: AppTheme.labelLarge),
                Text(
                  "$_destinationName · ${_numberController.text.trim()}",
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notice({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.textBlack),
            ),
          ),
        ],
      ),
    );
  }
}
