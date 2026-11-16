import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/afrilink_bank_connect_screen/afrilink_bank_connect_screen.dart';
import 'package:zentrapay_application/core/models/wallet.dart';
import 'package:zentrapay_application/core/models/saved_card.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/utils/Common/app_confirm_sheet.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/wallet_topup/gateway_checkout.dart';
import 'package:zentrapay_application/features/wallet_topup/models/response_entities.dart';
import 'package:zentrapay_application/features/wallet_topup/saved_cards_repository.dart';
import 'package:zentrapay_application/features/wallet_topup/saved_cards_screen.dart';
import 'package:zentrapay_application/features/wallet_topup/topup_service.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart';

/// The ONE wallet top-up entry point of the app. ZGrow's quick action, ZBank's "Top Up Wallet" row and
/// anything else that adds money to the wallet all open this same sheet, so the experience is identical
/// everywhere.
Future<void> showTopupSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext sheetContext) {
      final media = MediaQuery.of(sheetContext);
      return Container(
        decoration: BoxDecoration(
          color: AppTheme.gray50,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusXxl),
          ),
          border: Border.all(color: AppTheme.textBlack),
        ),
        // Never taller than 85% of the screen; the content scrolls when the keyboard takes the room
        constraints: BoxConstraints(
          maxHeight: media.size.height * 0.85,
          maxWidth: double.infinity,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingXxl,
            AppTheme.spacingMd,
            AppTheme.spacingLg + media.viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fund your zentrapay wallet',
                style: AppTheme.headlineMedium,
              ),
              AppTheme.divider(sheetContext, AppTheme.gray500),
              const SizedBox(height: AppTheme.spacingMd),
              const TopupScreen(),
            ],
          ),
        ),
      );
    },
  );
}

/// The top-up form: amount + currency, funding source, and the linked bank account the money comes from.
/// A top-up is only possible from a linked bank account that holds the chosen currency - without one the
/// form says so and offers to link a bank (the server enforces the same rule).
class TopupScreen extends StatefulWidget {
  const TopupScreen({super.key});

  @override
  State<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends State<TopupScreen> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Currency selection
  SupportedCurrencies? _selectedCurrency;
  bool _isCurrencyLoaded = false;
  bool _isSourcesLoaded = false;
  List<SupportedCurrencies> _availableCurrencies = [];
  FundingSources? _sources;

  // Payment state
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedSource;
  String? _selectedMethod;

  // null = pay through the gateway checkout; otherwise the id of the saved card to charge
  String? _selectedCardId;
  bool _saveCard = false;

  @override
  void initState() {
    super.initState();
    BankAccountsRepository.instance.ensureLoaded().catchError((_) => null);
    SavedCardsRepository.instance.ensureLoaded().catchError((_) {});
    _initialLoad();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // Loads the supported currencies and the funding sources (Card / Bank / Mobile Money) before the form is usable.
  Future<void> _initialLoad() async {
    setState(() => _isLoading = true);
    try {
      final currencies = await WalletsRepository.instance
          .getSupportedCurrencies();
      FundingSources? sources;
      try {
        sources = await FundingSourcesRepository.instance.ensureLoaded();
      } catch (e) {
        debugPrint('Funding sources failed to load: $e');
      }
      if (!mounted) return;
      setState(() {
        _availableCurrencies = currencies;
        // The dropdown shows the first currency until the user picks another, so it must also be the
        // one that is actually submitted.
        _selectedCurrency ??= currencies.isEmpty ? null : currencies.first;
        _isCurrencyLoaded = currencies.isNotEmpty;
        _sources = sources;
        _isSourcesLoaded = sources != null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isCurrencyLoaded = false;
        _errorMessage = errorMessage(
          e,
          fallback: 'We could not load the top-up options. Please try again.',
        );
      });
    }
  }

  /// Linked, active bank accounts that hold the selected currency (primary first).
  List<BankAccounts> _fundingBanks() {
    final code = _selectedCurrency?.currencyCode.toUpperCase();
    if (code == null) return const [];
    final all =
        BankAccountsRepository.instance.data?.accounts ??
        const <BankAccounts>[];
    final matches = all
        .where(
          (b) =>
              b.currencyCode.toUpperCase() == code &&
              b.connectionStatus.toLowerCase() == 'active',
        )
        .toList();
    matches.sort((a, b) => (b.isPrimary ? 1 : 0) - (a.isPrimary ? 1 : 0));
    return matches;
  }

  // Asks the backend for a checkout (Paystack first, Flutterwave as failover), then opens the gateway.
  Future<void> _continuePressed() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter an amount');
      return;
    }
    final currencyCode = _selectedCurrency?.currencyCode;
    if (currencyCode == null) {
      setState(() => _errorMessage = 'Currency code missing');
      return;
    }
    if (_selectedCardId != null) {
      await _chargeSavedCard(amount, currencyCode);
      return;
    }
    if (_selectedMethod == null ||
        _selectedMethod!.isEmpty ||
        _selectedSource == null ||
        _selectedSource!.isEmpty) {
      setState(() => _errorMessage = 'Select a funding source');
      return;
    }
    if (_fundingBanks().isEmpty) {
      setState(
        () => _errorMessage =
            'Link a $currencyCode bank account first - top-ups are drawn from a linked bank account.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    TopupResponse? checkout;
    String? gatewayUsed;
    String? refusal;
    for (final gateway in const ['paystack', 'flutterwave']) {
      try {
        final response = await TopupService.topup(
          amount: amount,
          currencyCode: currencyCode,
          gateway: gateway,
          source: _selectedSource!,
          paymentMethod: _selectedMethod!,
          saveCard: _saveCard,
        );
        final usable =
            response.status &&
            response.reference.isNotEmpty &&
            ((response.accessCode ?? '').isNotEmpty ||
                (response.authorizationUrl ?? '').isNotEmpty);
        if (usable) {
          checkout = response;
          gatewayUsed = gateway;
          break;
        }
      } catch (e) {
        // A 4xx means the server REFUSED the top-up itself (no linked bank in this currency, account
        // frozen ...) - another gateway would be refused too, so stop and show why. Anything else
        // (gateway down, timeout) is what the second gateway is for.
        if (e is DioException &&
            (e.response?.statusCode ?? 500) >= 400 &&
            (e.response?.statusCode ?? 500) < 500) {
          refusal = errorMessage(e);
          break;
        }
        debugPrint(
          '$gateway top-up could not start, trying the next gateway: $e',
        );
      }
    }

    if (!mounted) return;
    if (checkout == null || gatewayUsed == null) {
      setState(() {
        _isLoading = false;
        _errorMessage =
            refusal ??
            'We could not start the payment right now. Please try again in a moment.';
      });
      return;
    }

    setState(() {
      _isLoading = false;
    });
    await _openGatewaySdk(checkout: checkout, gateway: gatewayUsed);
  }

  // Opens the Paystack SDK / hosted checkout, then reports what the BACKEND confirmed.
  Future<void> _openGatewaySdk({
    required TopupResponse checkout,
    required String gateway,
  }) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final outcome = await GatewayCheckout.run(
      context,
      checkout: checkout,
      gateway: gateway,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    _handleOutcome(outcome);
  }

  // Charges a saved card: the transaction PIN authorises it, the backend decides the result.
  Future<void> _chargeSavedCard(double amount, String currencyCode) async {
    final repo = SavedCardsRepository.instance;
    SavedCard? card;
    for (final c in repo.cards) {
      if (c.id == _selectedCardId) card = c;
    }
    if (card == null) {
      setState(() => _errorMessage = 'Choose a card');
      return;
    }
    final pin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => AppConfirmPinSheet(
        name: 'your wallet from ${card!.label}',
        currencyCode: currencyCode,
        amount: amount.toStringAsFixed(2),
      ),
    );
    if (pin == null || pin.isEmpty || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    TopupOutcome outcome;
    try {
      final result = await repo.charge(
        cardId: card.id,
        amount: amount,
        currencyCode: currencyCode,
        pin: pin,
      );
      switch (result.status.toUpperCase()) {
        case 'SUCCESS':
          outcome = TopupOutcome.success;
        case 'FAILED':
          outcome = TopupOutcome.failed;
        default:
          outcome = await GatewayCheckout.awaitOutcome(
            result.reference,
            attempts: 4,
          );
      }
    } catch (e) {
      if (!mounted) return;
      // The attempt (wrong PIN, declined card ...) is saved in the history either way
      TransactionsRepository.instance
          .ensureLoaded(forceRefresh: true)
          .catchError((_) => null);
      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage(
          e,
          fallback: 'Your card could not be charged. Please try again.',
        );
      });
      return;
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    _handleOutcome(outcome);
  }

  void _handleOutcome(TopupOutcome outcome) {
    SavedCardsRepository.instance
        .ensureLoaded(forceRefresh: true)
        .catchError((_) {});
    switch (outcome) {
      case TopupOutcome.success:
        ZentraNotifier.success(
          'Wallet topped up',
          'Your payment was confirmed and your balance is updated.',
        );
        _amountController.clear();
        WalletsRepository.instance.refresh().catchError((_) => null);
        TransactionsRepository.instance
            .ensureLoaded(forceRefresh: true)
            .catchError((_) => null);
      case TopupOutcome.pending:
        ZentraNotifier.notice(
          'Payment processing - your balance updates once it is confirmed.',
        );
        WalletsRepository.instance.refresh().catchError((_) => null);
        TransactionsRepository.instance
            .ensureLoaded(forceRefresh: true)
            .catchError((_) => null);
      case TopupOutcome.failed:
        setState(
          () => _errorMessage =
              'The payment was not completed. You have not been charged.',
        );
        TransactionsRepository.instance
            .ensureLoaded(forceRefresh: true)
            .catchError((_) => null);
      case TopupOutcome.cancelled:
        break;
    }
  }

  Future<void> _linkBank() async {
    final linked = await linkBankWithAfriLink(context);
    if (linked != null && mounted) {
      await BankAccountsRepository.instance
          .ensureLoaded(forceRefresh: true)
          .catchError((_) => null);
      if (mounted) setState(() => _errorMessage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([
        BankAccountsRepository.instance,
        SavedCardsRepository.instance,
      ]),
      builder: (context, _) {
        final usingSavedCard =
            _selectedCardId != null &&
            SavedCardsRepository.instance.usable.any(
              (c) => c.id == _selectedCardId,
            );
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppTheme.spacingLg,
            children: [
              _buildAmountField(theme),
              _payWithSection(),
              if (usingSavedCard)
                _savedCardNote()
              else ...[
                _sourceAndMethodFields(theme),
                _fundingBankCard(),
                _saveCardSwitch(),
              ],
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ElevatedButton(
                      onPressed: _continuePressed,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16.0),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text('Continue'),
                    ),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: AppTheme.spacingSm),
            ],
          ),
        );
      },
    );
  }

  // Choose between the gateway checkout and one of the saved cards
  Widget _payWithSection() {
    final cards = SavedCardsRepository.instance.usable;
    if (cards.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Pay with', style: AppTheme.labelLarge),
            const Spacer(),
            TextButton(
              onPressed: _manageCards,
              child: const Text('Manage cards'),
            ),
          ],
        ),
        Wrap(
          spacing: AppTheme.spacingSm,
          runSpacing: AppTheme.spacingSm,
          children: [
            ChoiceChip(
              label: const Text('Checkout'),
              selected: _selectedCardId == null,
              onSelected: (_) => setState(() {
                _selectedCardId = null;
                _errorMessage = null;
              }),
            ),
            for (final c in cards)
              ChoiceChip(
                avatar: const Icon(Icons.credit_card_rounded, size: 16),
                label: Text(c.label),
                selected: _selectedCardId == c.id,
                onSelected: (_) => setState(() {
                  _selectedCardId = c.id;
                  _errorMessage = null;
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _savedCardNote() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withAlpha(24),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.successGreen.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: AppTheme.textBlack),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Text(
              'Your saved card is charged straight away - you only confirm with your PIN.',
              style: AppTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveCardSwitch() {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _saveCard,
      thumbColor: WidgetStateProperty.all(AppTheme.primaryWhite),
      inactiveTrackColor: AppTheme.primaryPink,
      activeTrackColor: AppTheme.secondaryNavy,
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      onChanged: (v) => setState(() => _saveCard = v),
      title: Text('Save my card for next time', style: AppTheme.labelLarge),
      subtitle: Text(
        'If you pay by card, the payment provider keeps it so you can top up with just your PIN. We never see the card number.',
        style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
      ),
    );
  }

  void _manageCards() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SavedCardsScreen()));
  }

  // Which linked bank account the money is drawn from - or why the top-up cannot start yet
  Widget _fundingBankCard() {
    final code = _selectedCurrency?.currencyCode ?? '';
    final banks = _fundingBanks();
    final loading =
        BankAccountsRepository.instance.isLoading &&
        BankAccountsRepository.instance.data == null;
    if (loading) {
      return const SizedBox.shrink();
    }
    final hasBank = banks.isNotEmpty;
    final tone = hasBank ? AppTheme.successGreen : AppTheme.warningOrange;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: tone.withAlpha(24),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: tone.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(
            hasBank ? Icons.account_balance_rounded : Icons.link_off_rounded,
            color: AppTheme.textBlack,
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasBank
                      ? 'Paid from your linked bank'
                      : 'No $code bank linked',
                  style: AppTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  hasBank
                      ? '${banks.first.displayName}'
                            '${banks.first.lastDigits.isEmpty ? '' : '  ••${banks.first.lastDigits}'}'
                            '${banks.length > 1 ? '  +${banks.length - 1} more' : ''}'
                      : 'Top-ups come from a linked bank account that holds $code.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ],
            ),
          ),
          if (!hasBank)
            TextButton(onPressed: _linkBank, child: const Text('Link bank')),
        ],
      ),
    );
  }

  Widget _buildAmountField(ThemeData theme) {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount',
        labelStyle: AppTheme.bodyLarge,
        hintText: 'Enter amount (e.g., 100.00)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        suffix: _isCurrencyLoaded
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.25,
                ),
                child: PopupMenuButton<SupportedCurrencies>(
                  color: AppTheme.gray100,
                  elevation: 4,
                  onSelected: (SupportedCurrencies currency) {
                    setState(() {
                      _selectedCurrency = currency;
                      _errorMessage = null;
                    });
                  },
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                  ),
                  itemBuilder: (BuildContext context) {
                    return _availableCurrencies.map((
                      SupportedCurrencies currency,
                    ) {
                      return PopupMenuItem<SupportedCurrencies>(
                        value: currency,
                        child: Text(
                          currency.currencyCode,
                          style: AppTheme.labelLarge,
                        ),
                      );
                    }).toList();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCurrency?.currencyCode ??
                            _availableCurrencies[0].currencyCode,
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              )
            : CircularProgressIndicator(color: AppTheme.buttonColor),
      ),
    );
  }

  // Widget displaying funding source and payment method side-by-side in a Row
  Widget _sourceAndMethodFields(ThemeData theme) {
    return Row(
      children: [
        // 1. Funding Source Dropdown taking 50% width
        Expanded(
          child: PopupMenuButton<FundingSource>(
            color: AppTheme.gray100,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            onSelected: (FundingSource source) {
              setState(() {
                _selectedSource = source.name;
                _selectedMethod =
                    source.method; // Automatically auto-populate payment method
              });
            },
            itemBuilder: (BuildContext context) {
              return _isSourcesLoaded && _sources != null
                  ? _sources!.sources.map((FundingSource source) {
                      return PopupMenuItem<FundingSource>(
                        value: source,
                        child: Text(source.name, style: AppTheme.labelLarge),
                      );
                    }).toList()
                  : [
                      const PopupMenuItem<FundingSource>(
                        enabled: false,
                        child: Text('Loading sources...'),
                      ),
                    ];
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Funding Source',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: BorderSide(color: AppTheme.gray300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedSource ?? 'Select Source',
                      style: AppTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: AppTheme.spacingMd),

        // 2. Payment Method Display taking 50% width (auto-populated from source)
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Payment Method',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                borderSide: BorderSide(color: AppTheme.gray300),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _selectedMethod ?? 'Auto-selected',
                    style: AppTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
