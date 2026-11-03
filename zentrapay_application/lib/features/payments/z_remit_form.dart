import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/money.dart';
import 'package:zentrapay_application/core/models/reference_data.dart';
import 'package:zentrapay_application/core/models/search_result.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/utils/Common/app_confirm_sheet.dart';
import 'package:zentrapay_application/core/utils/Common/transaction_result_overlay.dart';
import 'package:zentrapay_application/core/utils/loading_overlay.dart';
import 'package:zentrapay_application/core/utils/payment_currency.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/pay_search_section.dart';
import 'package:zentrapay_application/features/home/HomePayments/widgets/verify_payee_sheet.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/payments/repository/cache_payments_data.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profile_data.dart';
import 'package:zentrapay_application/features/zgrow/emergency/emergency_vault.dart';
import 'package:zentrapay_application/features/zremit/repository/cache_zremit_data.dart';

/// Who the money is going to: an app user, or a bank / mobile-money account
/// that the payment providers have already confirmed.
class _RemitRecipient {
  final String type; // USER | BANK | MOBILE_MONEY
  final String name;
  final String detail;
  final String countryCode;
  final String? userId;
  final String? phoneNumber;
  final String? bankId;
  final String? bankCode;
  final String? accountNumber;
  final String? momoProviderId;
  final String? momoProviderCode;

  const _RemitRecipient({
    required this.type,
    required this.name,
    required this.detail,
    required this.countryCode,
    this.userId,
    this.phoneNumber,
    this.bankId,
    this.bankCode,
    this.accountNumber,
    this.momoProviderId,
    this.momoProviderCode,
  });

  IconData get icon => switch (type) {
    'BANK' => Icons.account_balance_outlined,
    'MOBILE_MONEY' => Icons.phone_android_outlined,
    _ => Icons.person_outline,
  };

  String get channel => switch (type) {
    'BANK' => 'Bank',
    'MOBILE_MONEY' => 'Mobile Money',
    _ => 'Wallet',
  };
}

/// ZRemit: cross-border sends only. The search only returns people, banks and
/// mobile-money networks OUTSIDE the sender's own country (the backend enforces
/// the same rule), and bank / mobile-money accounts are confirmed with the
/// payment providers before the PIN is ever asked for.
class ZRemitForm extends StatefulWidget {
  const ZRemitForm({super.key});

  @override
  State<ZRemitForm> createState() => ZRemitFormState();
}

class ZRemitFormState extends State<ZRemitForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(
    text: "0.00",
  );
  final TextEditingController _receiveController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _receiverController = TextEditingController();

  // The destination country the user picked; everything else (currency,
  // recipient search) follows from it.
  AppCountry? _country;
  String _senderCountryCode = "";

  Timer? _searchDebounce;
  bool _searching = false;
  ContactSearchResult _results = ContactSearchResult.empty();

  _RemitRecipient? _recipient;
  String _sourceCurrency = "";
  String _destinationCurrency = "";

  // The default currency of the country the sender registered in - the only
  // currency they can send from (the destination is the other country's).
  String _homeCurrency = "";

  // Live conversion preview (debounced, one-shot per change - not a cache).
  Timer? _previewDebounce;
  bool _previewLoading = false;
  String? _previewError;
  String? _previewRate;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WalletsRepository.instance.ensureLoaded().catchError((_) => null);
    CountriesRepository.instance.ensureLoaded().catchError((_) => null);
    WalletsRepository.instance.addListener(_onWalletsChanged);
    UserProfileRepository.instance
        .ensureLoaded()
        .then((snapshot) {
          if (!mounted || snapshot == null) return;
          setState(() => _senderCountryCode = snapshot.user.countryCode);
        })
        .catchError((_) {});
    PaymentCurrency.ofSender().then((code) {
      if (!mounted || code.isEmpty) return;
      setState(() => _homeCurrency = code);
      _schedulePreview();
    });
  }

  @override
  void dispose() {
    WalletsRepository.instance.removeListener(_onWalletsChanged);
    _searchDebounce?.cancel();
    _previewDebounce?.cancel();
    _searchController.dispose();
    _amountController.dispose();
    _receiveController.dispose();
    _reasonController.dispose();
    _receiverController.dispose();
    super.dispose();
  }

  void _onWalletsChanged() {
    if (mounted) setState(() {});
  }

  /// Currencies the sender can send from: the one they registered with, if
  /// they hold an account in it (any held currency while that is unknown).
  List<String> get _sourceCurrencies {
    final accounts = WalletsRepository.instance.data?.fiatAccounts ?? const [];
    final held = accounts.map((a) => a.currencyCode).toSet();
    if (_homeCurrency.isEmpty) return held.toList();
    return held.where((c) => c.toUpperCase() == _homeCurrency).toList();
  }

  String get _effectiveSource {
    final options = _sourceCurrencies;
    if (options.isEmpty) {
      return _homeCurrency.isNotEmpty ? _homeCurrency : _sourceCurrency;
    }
    if (options.contains(_sourceCurrency)) return _sourceCurrency;
    // Once the registered currency is known it is the only option
    if (_homeCurrency.isNotEmpty) return options.first;
    final defaults = WalletsRepository.instance.data!.fiatAccounts
        .where((a) => a.isDefault)
        .map((a) => a.currencyCode);
    return defaults.isNotEmpty ? defaults.first : options.first;
  }

  // ---- search -----------------------------------------------------------

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = ContactSearchResult.empty();
        _searching = false;
      });
      return;
    }
    setState(() {});
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _searching = true);
      try {
        final result = await SearchRepository.search(
          query,
          international: true,
          country: _country?.countryCode,
        );
        if (!mounted) return;
        setState(() => _results = result);
      } catch (e) {
        debugPrint("ZRemit search error: $e");
      } finally {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  void _pickRecipient(_RemitRecipient recipient) {
    setState(() {
      _recipient = recipient;
      _results = ContactSearchResult.empty();
      _searchController.clear();
      // The receiver name defaults to the verified name; the user can still
      // correct it.
      if (_receiverController.text.trim().isEmpty) {
        _receiverController.text = recipient.name;
      }
    });
    _schedulePreview();
  }

  // ---- destination country ----------------------------------------------

  Future<void> _chooseCountry() async {
    final all =
        await CountriesRepository.instance.ensureLoaded().catchError(
          (_) => <AppCountry>[],
        ) ??
        const <AppCountry>[];
    if (!mounted) return;
    final options =
        all
            .where(
              (c) =>
                  c.countryCode.toUpperCase() !=
                  _senderCountryCode.toUpperCase(),
            )
            .toList()
          ..sort((a, b) => a.countryName.compareTo(b.countryName));
    final picked = await showModalBottomSheet<AppCountry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountrySheet(countries: options, selected: _country),
    );
    if (picked == null || !mounted) return;
    if (picked.countryCode == _country?.countryCode) return;
    setState(() {
      _country = picked;
      // The currency is the destination country's default currency.
      _destinationCurrency = picked.defaultCurrencyCode.trim().toUpperCase();
      // A recipient from another country no longer applies.
      _recipient = null;
      _results = ContactSearchResult.empty();
      _searchController.clear();
    });
    _schedulePreview();
  }

  void _onSelectUser(SearchAppUser user) {
    _pickRecipient(
      _RemitRecipient(
        type: 'USER',
        name: user.fullName.isNotEmpty ? user.fullName : user.phoneNumber,
        detail: user.zentag.isNotEmpty ? user.zentag : user.phoneNumber,
        countryCode: user.countryCode,
        userId: user.userId,
        phoneNumber: user.phoneNumber,
      ),
    );
  }

  Future<void> _onSelectBank(Banks bank) async {
    final payee = await showVerifyPayeeSheet(context: context, bank: bank);
    if (payee == null || !mounted) return;
    _pickRecipient(
      _RemitRecipient(
        type: 'BANK',
        name: payee.displayName,
        detail: "${payee.destinationName} · ${payee.accountNumber}",
        countryCode: payee.countryCode,
        bankId: bank.bankId,
        bankCode: bank.bankCode,
        accountNumber: payee.accountNumber,
      ),
    );
  }

  Future<void> _onSelectMobileMoney(MobileMoneyProvider momo) async {
    final payee = await showVerifyPayeeSheet(
      context: context,
      mobileMoney: momo,
    );
    if (payee == null || !mounted) return;
    _pickRecipient(
      _RemitRecipient(
        type: 'MOBILE_MONEY',
        name: payee.displayName,
        detail: "${payee.destinationName} · ${payee.accountNumber}",
        countryCode: payee.countryCode,
        phoneNumber: payee.accountNumber,
        momoProviderId: momo.providerId,
        momoProviderCode: momo.providerCode,
      ),
    );
  }

  // ---- amount + preview -------------------------------------------------

  void _formatAmount(String value) {
    final clean = value.replaceAll(RegExp(r'[^0-9]'), '');
    final formatted = clean.isEmpty
        ? "0.00"
        : (double.parse(clean) / 100).toStringAsFixed(2);
    _amountController.text = formatted;
    _amountController.selection = TextSelection.fromPosition(
      TextPosition(offset: formatted.length),
    );
    _schedulePreview();
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 400), _updatePreview);
  }

  Future<void> _updatePreview() async {
    final from = _effectiveSource;
    final to = _destinationCurrency;
    final amount = _amountController.text;
    if (from.isEmpty || to.isEmpty || amount.toAmount() <= 0) {
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
        _previewError = null;
        _previewRate = null;
        _receiveController.text = "";
      });
      return;
    }
    if (from == to) {
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
        _previewError = null;
        _previewRate = null;
        _receiveController.text = amount;
      });
      return;
    }
    setState(() => _previewLoading = true);
    try {
      final result = await ConverterService.convert(
        from: from,
        to: to,
        amount: amount,
      );
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
        _previewError = null;
        _previewRate = result.rate;
        _receiveController.text = formatMoney(result.convertedAmount);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _previewLoading = false;
        _previewError = "Rate unavailable";
      });
    }
  }

  // ---- send -------------------------------------------------------------

  Future<void> _send() async {
    if (_country == null) {
      await showTransactionResultOverlay(
        context: context,
        status: TransactionResultStatus.error,
        title: "Choose a destination",
        message: "Pick the country you are sending money to first.",
      );
      return;
    }
    final recipient = _recipient;
    if (recipient == null) {
      await showTransactionResultOverlay(
        context: context,
        status: TransactionResultStatus.error,
        title: "Choose a recipient",
        message: "Search for a person, bank or mobile money network first.",
      );
      return;
    }
    if (!_formKey.currentState!.validate() || _sending) return;
    final receiverName = _receiverController.text.trim();

    final source = _effectiveSource;
    if (source.isEmpty) return;
    final amount = _amountController.text;

    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AppConfirmPinSheet(
        name: receiverName,
        currencyCode: source,
        amount: amount,
      ),
    );
    if (pin == null || pin.isEmpty || !mounted) return;

    setState(() => _sending = true);
    try {
      final data = await LoadingOverlay.run(
        () => RemittanceService.send(
          pin: pin,
          amount: amount,
          sourceCurrencyCode: source,
          destinationCurrencyCode: _destinationCurrency.isEmpty
              ? source
              : _destinationCurrency,
          channel: recipient.channel,
          recipientName: receiverName,
          recipientPhoneNumber: recipient.phoneNumber,
          recipientUserId: recipient.userId,
          recipientCountryCode: _country!.countryCode,
          purpose: _reasonController.text.trim(),
          recipientType: recipient.type,
          bankId: recipient.bankId,
          bankCode: recipient.bankCode,
          accountNumber: recipient.accountNumber,
          mobileMoneyProviderId: recipient.momoProviderId,
          mobileMoneyProviderCode: recipient.momoProviderCode,
        ),
        message: "Sending your money…",
      );
      _syncAfterAttempt();
      // Emergency Vault round-up (no-op unless the vault is on).
      int savedMinor = 0;
      try {
        savedMinor = await EmergencyVault.instance.recordRoundUp(
          amount: amount.toAmount(),
          currency: source,
        );
      } catch (e) {
        debugPrint('Emergency vault round-up failed: $e');
      }
      if (!mounted) return;
      final status =
          ((data['remittance'] is Map ? data['remittance']['status'] : null) ??
                  '')
              .toString();
      await showTransactionResultOverlay(
        context: context,
        status: TransactionResultStatus.success,
        title: status.toUpperCase() == 'PENDING'
            ? "Transfer on its way"
            : "Transfer sent",
        message: "$source $amount sent to $receiverName.",
        details: [
          TransactionResultDetail("Recipient", receiverName),
          TransactionResultDetail("Country", _country!.countryName),
          TransactionResultDetail("Destination", recipient.detail),
          TransactionResultDetail("Amount", "$source $amount"),
          if (_receiveController.text.isNotEmpty &&
              _destinationCurrency.isNotEmpty)
            TransactionResultDetail(
              "They get (approx.)",
              "$_destinationCurrency ${_receiveController.text}",
            ),
          if (status.isNotEmpty) TransactionResultDetail("Status", status),
          if (savedMinor > 0)
            TransactionResultDetail(
              "Saved to Emergency Vault",
              EmergencyVault.formatMinor(savedMinor, currency: source),
            ),
        ],
      );
      reset();
    } catch (e) {
      _syncAfterAttempt();
      if (!mounted) return;
      await showTransactionResultOverlay(
        context: context,
        status: TransactionResultStatus.error,
        title: "Transfer failed",
        message: _messageOf(e),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // Sent, still processing or refused: the attempt is on the server, so the
  // history and balance follow right away - before the result sheet is even
  // dismissed (an open payout is re-checked automatically).
  void _syncAfterAttempt() {
    TransactionsRepository.instance.syncLatest();
    WalletsRepository.instance.refresh().catchError((_) => null);
  }

  String _messageOf(Object e) {
    if (e is DioException && e.response?.data is Map) {
      final message = (e.response!.data as Map)['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return "Something went wrong! Please try again. No money was deducted from your account.";
  }

  /// Clears the form after a successful send.
  void reset() {
    setState(() {
      _recipient = null;
      _country = null;
      _destinationCurrency = "";
      _receiverController.clear();
      _amountController.text = "0.00";
      _receiveController.clear();
      _reasonController.clear();
      _previewError = null;
      _previewRate = null;
    });
    _formKey.currentState?.reset();
  }

  // ---- UI ---------------------------------------------------------------

  InputDecoration _decoration({String? hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppTheme.textBlack.withAlpha(128)),
      suffixIcon: suffix,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide(color: AppTheme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide(color: AppTheme.brand, width: 2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        borderSide: BorderSide(color: AppTheme.dividerColor),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: AppTheme.labelSmall.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  Widget _recipientCard(_RemitRecipient r) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.brand.withValues(alpha: 0.1),
            child: Icon(r.icon, color: AppTheme.textBlack),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelLarge,
                ),
                Text(
                  "${r.detail} · ${r.countryCode}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _recipient = null),
            child: const Text("Change"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sources = _sourceCurrencies;
    final source = _effectiveSource;
    final recipient = _recipient;
    final sameCurrency =
        _destinationCurrency.isNotEmpty && source == _destinationCurrency;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Send money abroad", style: AppTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            "Choose where the money is going, who receives it and how.",
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _label("Destination country"),
          InkWell(
            onTap: _chooseCountry,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            child: InputDecorator(
              decoration: _decoration(
                suffix: Icon(Icons.keyboard_arrow_down, color: AppTheme.gray500),
              ),
              child: Text(
                _country?.countryName ?? "Select a country",
                style: TextStyle(
                  fontSize: 16,
                  color: _country == null
                      ? AppTheme.textBlack.withAlpha(128)
                      : AppTheme.textBlack,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _label("Currency"),
          InputDecorator(
            decoration: _decoration(
              suffix: Icon(Icons.lock_outline, size: 18, color: AppTheme.gray500),
            ),
            child: Text(
              _destinationCurrency.isEmpty
                  ? "Set by the destination country"
                  : _destinationCurrency,
              style: TextStyle(
                fontSize: 16,
                fontWeight: _destinationCurrency.isEmpty
                    ? FontWeight.normal
                    : FontWeight.bold,
                color: _destinationCurrency.isEmpty
                    ? AppTheme.textBlack.withAlpha(128)
                    : AppTheme.textBlack,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _label("Receiver name"),
          TextFormField(
            controller: _receiverController,
            textCapitalization: TextCapitalization.words,
            cursorColor: AppTheme.textBlack,
            decoration: _decoration(hint: "Full name of the person receiving"),
            validator: (val) => val == null || val.trim().length < 2
                ? "Enter the receiver's name"
                : null,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _label("Send to"),
          if (_country == null)
            Text(
              "Pick a destination country to search its people, banks and mobile money.",
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
            )
          else if (recipient == null)
            PaySearchSection(
              controller: _searchController,
              isSearching: _searching,
              searchResult: _results,
              onChanged: _onSearchChanged,
              hintText: "Search people, banks, mobile money in ${_country!.countryName}...",
              onSelectUser: _onSelectUser,
              onSelectBillProvider: (_) {},
              onSelectBank: _onSelectBank,
              onSelectMobileMoney: _onSelectMobileMoney,
            )
          else
            _recipientCard(recipient),
          const SizedBox(height: AppTheme.spacingLg),
          _label("You send"),
          TextFormField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            cursorColor: AppTheme.textBlack,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: _decoration(
              suffix: sources.isEmpty
                  ? null
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: source,
                          items: sources
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(
                                    c,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setState(() => _sourceCurrency = val);
                            _schedulePreview();
                          },
                        ),
                      ),
                    ),
            ),
            onChanged: _formatAmount,
            validator: (val) {
              if (val == null || val.isEmpty || val.toAmount() <= 0) {
                return "Please enter a valid amount";
              }
              return null;
            },
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _label(
            sameCurrency ? "Same currency transfer" : "They get (approx.)",
          ),
          TextFormField(
            controller: _receiveController,
            readOnly: true,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            decoration: _decoration(
              hint: recipient == null ? "Choose a recipient first" : null,
              suffix: _destinationCurrency.isEmpty
                  ? null
                  : Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _destinationCurrency,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ),
          if (!sameCurrency && _destinationCurrency.isNotEmpty) ...[
            const SizedBox(height: 6),
            if (_previewLoading)
              Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Fetching live rate…",
                    style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                  ),
                ],
              )
            else if (_previewError != null)
              Text(
                _previewError!,
                style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
              )
            else if (_previewRate != null)
              Text(
                "1 $source = $_previewRate $_destinationCurrency",
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
          ],
          const SizedBox(height: AppTheme.spacingLg),
          _label("Reason / purpose"),
          TextFormField(
            controller: _reasonController,
            maxLines: 2,
            cursorColor: AppTheme.textBlack,
            decoration: _decoration(hint: "Enter reason for transfer..."),
            validator: (val) => val == null || val.trim().isEmpty
                ? "Please provide a reason"
                : null,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.buttonColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _sending ? null : _send,
              child: const Text(
                "Continue to Payment",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Searchable list of destination countries (the sender's own country is not
/// offered: ZRemit is cross-border only).
class _CountrySheet extends StatefulWidget {
  final List<AppCountry> countries;
  final AppCountry? selected;

  const _CountrySheet({required this.countries, this.selected});

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final shown = widget.countries
        .where(
          (c) =>
              q.isEmpty ||
              c.countryName.toLowerCase().contains(q) ||
              c.countryCode.toLowerCase().contains(q) ||
              c.defaultCurrencyCode.toLowerCase().contains(q),
        )
        .toList();
    final height = MediaQuery.of(context).size.height * 0.7;
    return Container(
      height: height,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXxl),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: AppTheme.spacingSm),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: TextField(
              cursorColor: AppTheme.textBlack,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: "Search country or currency",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  borderSide: BorderSide(color: AppTheme.dividerColor),
                ),
              ),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      widget.countries.isEmpty
                          ? "No destination countries available."
                          : "No match.",
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.gray500,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: shown.length,
                    itemBuilder: (_, i) {
                      final c = shown[i];
                      final isSelected =
                          c.countryCode == widget.selected?.countryCode;
                      return ListTile(
                        title: Text(c.countryName, style: AppTheme.labelLarge),
                        subtitle: Text(
                          c.defaultCurrencyCode,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.gray500,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: AppTheme.brand)
                            : null,
                        onTap: () => Navigator.pop(context, c),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
