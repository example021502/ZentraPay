import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/converter.dart';
import 'package:zentrapay_application/core/models/reference_data.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/Common/format_date_time_string.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/payments/repository/cache_payments_data.dart';
import 'package:zentrapay_application/main.dart';

/// Smart currency converter.
///
/// Currencies and rates come from the backend. While the user types, the
/// result is a *preview* worked out from the live rate (nothing is recorded);
/// "Convert & save" sends the conversion to the backend, which records it in
/// the user's conversion history (the clock button opens that history).
class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String _from = 'GHS';
  String _to = 'USD';
  final _amountController = TextEditingController(text: '100.00');

  List<AppCurrency> _currencies = const [];
  RatesSnapshot? _rates;
  DateTime? _ratesAt;
  bool _loadingRates = true;
  bool _converting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- data

  Future<void> _loadRates({bool refresh = false}) async {
    setState(() {
      _loadingRates = true;
      _error = null;
    });
    try {
      try {
        final list = await CurrenciesRepository.instance.ensureLoaded();
        if (list != null && mounted) {
          _currencies = list.where((c) => !c.isCrypto).toList();
        }
      } catch (_) {
        // The rates alone are enough to convert; names/symbols are cosmetic.
      }
      final repo = RatesRepository.instance;
      await repo.loadForBase(_from);
      if (refresh) await repo.ensureLoaded(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _rates = repo.data;
        _ratesAt = DateTime.now();
        _keepSelectionValid();
      });
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = errorMessage(
          e,
          fallback: "We couldn't load live rates right now.",
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingRates = false);
    }
  }

  /// Codes the user can pick: the backend's currency list, falling back to the
  /// codes it returned rates for.
  List<String> get _codes {
    final fromList = _currencies.map((c) => c.currencyCode).toList();
    if (fromList.isNotEmpty) return fromList;
    return {_from, ...?_rates?.rates.keys}.toList()..sort();
  }

  void _keepSelectionValid() {
    final codes = _codes;
    if (codes.isEmpty) return;
    if (!codes.contains(_from)) _from = codes.first;
    if (!codes.contains(_to)) {
      _to = codes.firstWhere((c) => c != _from, orElse: () => codes.first);
    }
  }

  AppCurrency? _currency(String code) {
    for (final c in _currencies) {
      if (c.currencyCode == code) return c;
    }
    return null;
  }

  double? get _amount => double.tryParse(_amountController.text.trim());

  /// Units of [_to] for one unit of [_from], from the backend's snapshot.
  double? get _rate {
    if (_from == _to) return 1;
    if (_rates == null || _rates!.base != _from) return null;
    return double.tryParse(_rates!.rates[_to] ?? '');
  }

  double? get _preview {
    final amount = _amount;
    final rate = _rate;
    if (amount == null || rate == null) return null;
    return amount * rate;
  }

  // ------------------------------------------------------------- actions

  void _setFrom(String code) {
    if (code == _from) return;
    setState(() => _from = code);
    _loadRates();
  }

  void _setTo(String code) => setState(() => _to = code);

  void _swap() {
    final received = _preview;
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
      if (received != null && received > 0) {
        _amountController.text = received.toStringAsFixed(2);
      }
    });
    _loadRates();
  }

  Future<void> _convertAndSave() async {
    final amount = _amount;
    if (amount == null || amount <= 0) {
      ZentraNotifier.notice('Enter an amount to convert.');
      return;
    }
    if (_from == _to) {
      ZentraNotifier.notice('Choose two different currencies.');
      return;
    }
    setState(() => _converting = true);
    try {
      final result = await ConverterService.convert(
        from: _from,
        to: _to,
        amount: amount.toStringAsFixed(2),
      );
      if (!mounted) return;
      final converted = double.tryParse(result.convertedAmount);
      ZentraNotifier.success(
        'Conversion saved',
        '${amount.toStringAsFixed(2)} $_from = '
            '${converted?.toStringAsFixed(2) ?? result.convertedAmount} $_to',
      );
    } catch (e) {
      ZentraNotifier.error(
        'Conversion failed',
        errorMessage(
          e,
          fallback: "We couldn't complete that conversion. Please try again.",
        ),
      );
    } finally {
      if (mounted) setState(() => _converting = false);
    }
  }

  void _showHistory() {
    showAppOverlaySheet<void>(
      context: context,
      minHeightFraction: 0.6,
      maxWidth: 600,
      builder: (_) => const _ConversionHistory(),
    );
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Column(
        children: [
          SectionHeader(
            title: "Smart Converter",
            subtitle: "Live rates between your currencies",
            icon: Icons.currency_exchange_rounded,
            showBack: true,
            sheetColor: AppTheme.gray50,
            actions: [
              SectionHeaderButton(
                icon: Icons.history,
                tooltip: 'Conversion history',
                onTap: _showHistory,
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Column(
                children: [
                  _buildConverterCard(),
                  const SizedBox(height: 20),
                  _buildRateInfo(),
                  const SizedBox(height: 20),
                  _buildSummary(),
                  const SizedBox(height: 20),
                  _buildConvertButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    width: double.infinity,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(16),
    decoration: AppTheme.cardDecoration,
    child: child,
  );

  Widget _buildConverterCard() {
    final preview = _preview;
    return _card(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            children: [
              _field(
                label: 'Convert from',
                code: _from,
                onCode: _setFrom,
                input: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  style: AppTheme.headlineSmall,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                ),
              ),
              const SizedBox(height: 44),
              _field(
                label: 'Converted to',
                code: _to,
                onCode: _setTo,
                input: Text(
                  _loadingRates && preview == null
                      ? '…'
                      : preview == null
                      ? '--'
                      : preview.toStringAsFixed(2),
                  style: AppTheme.headlineSmall,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: _swap,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.brand,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.surface, width: 3),
              ),
              child: Icon(Icons.swap_vert, color: AppTheme.textBlack, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required String code,
    required ValueChanged<String> onCode,
    required Widget input,
  }) {
    final info = _currency(code);
    final codes = _codes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.gray50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
              ),
              Flexible(
                child: Text(
                  info?.currencyName ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (info != null && info.symbol.isNotEmpty) ...[
                Text(
                  info.symbol,
                  style: AppTheme.headlineSmall.copyWith(
                    color: AppTheme.gray500,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Expanded(child: input),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: codes.contains(code) ? code : null,
                    isDense: true,
                    dropdownColor: AppTheme.surface,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: AppTheme.textBlack,
                    ),
                    items: [
                      for (final c in codes)
                        DropdownMenuItem(
                          value: c,
                          child: Text(
                            '${_flag(c)} $c',
                            style: AppTheme.labelLarge,
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) onCode(v);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Flag emoji from the first two letters of the code (GHS -> GH). Codes that
  /// are not country-based just get a generic marker.
  String _flag(String code) {
    if (code.length < 2) return '💱';
    final a = code.codeUnitAt(0), b = code.codeUnitAt(1);
    bool isLetter(int u) => u >= 65 && u <= 90;
    if (!isLetter(a) || !isLetter(b)) return '💱';
    return String.fromCharCodes([0x1F1E6 + a - 65, 0x1F1E6 + b - 65]);
  }

  Widget _buildRateInfo() {
    final rate = _rate;
    final updated = _ratesAt == null
        ? null
        : '${_ratesAt!.hour.toString().padLeft(2, '0')}:'
              '${_ratesAt!.minute.toString().padLeft(2, '0')}';
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Exchange rate", style: AppTheme.labelLarge),
              _loadingRates
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.brand,
                      ),
                    )
                  : InkWell(
                      onTap: () => _loadRates(refresh: true),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.refresh,
                          size: 20,
                          color: AppTheme.textBlack,
                        ),
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(
              _error!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
            )
          else if (rate == null)
            Text(
              _loadingRates
                  ? 'Loading live rates…'
                  : 'No rate available for this pair.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
            )
          else ...[
            Text(
              '1 $_from = ${_formatRate(rate)} $_to',
              style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '1 $_to = ${_formatRate(1 / rate)} $_from',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
            ),
            if (updated != null) ...[
              const SizedBox(height: 4),
              Text(
                'Rates loaded at $updated',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatRate(double value) {
    if (value >= 100) return value.toStringAsFixed(2);
    if (value >= 1) return value.toStringAsFixed(4);
    return value.toStringAsFixed(6);
  }

  Widget _buildSummary() {
    final amount = _amount;
    final preview = _preview;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Conversion summary", style: AppTheme.labelLarge),
          const SizedBox(height: 12),
          _summaryRow(
            "You convert",
            amount == null ? '--' : '${amount.toStringAsFixed(2)} $_from',
          ),
          const SizedBox(height: 8),
          _summaryRow(
            "You receive",
            preview == null ? '--' : '${preview.toStringAsFixed(2)} $_to',
            highlighted: true,
          ),
          const SizedBox(height: 8),
          Text(
            "Saved to your history when you tap Convert & save.",
            style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool highlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
        ),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
            color: highlighted ? AppColors.green : AppTheme.textBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildConvertButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: 'Convert & save',
          loading: _converting,
          onPressed: _loadingRates || _rate == null ? null : _convertAndSave,
        ),
      ),
    );
  }
}

/// Overlay listing every conversion the user has saved (newest first).
class _ConversionHistory extends StatefulWidget {
  const _ConversionHistory();

  @override
  State<_ConversionHistory> createState() => _ConversionHistoryState();
}

class _ConversionHistoryState extends State<_ConversionHistory> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await ConverterHistoryRepository.instance.ensureLoaded();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _error = errorMessage(
          e,
          fallback: "We couldn't load your conversion history.",
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: ListenableBuilder(
        listenable: ConverterHistoryRepository.instance,
        builder: (context, _) {
          final repo = ConverterHistoryRepository.instance;
          final items = [...?repo.data]
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Conversion history', style: AppTheme.headlineSmall),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                'Everything you have converted with Smart Converter.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Expanded(child: _body(repo, items)),
            ],
          );
        },
      ),
    );
  }

  Widget _body(
    ConverterHistoryRepository repo,
    List<ConversionHistoryEntry> items,
  ) {
    if (repo.isLoading && repo.data == null) {
      return Center(child: CircularProgressIndicator(color: AppTheme.brand));
    }
    if (_error != null && repo.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            TextButton(onPressed: _load, child: const Text('Try again')),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No conversions yet. Tap Convert & save to keep a record.',
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingSm),
      itemBuilder: (context, i) => _HistoryTile(entry: items[i]),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ConversionHistoryEntry entry;

  const _HistoryTile({required this.entry});

  String _fixed(String raw) {
    final v = double.tryParse(raw);
    return v == null ? raw : v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingSm + 4),
      decoration: AppTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.brand.withAlpha(AppTheme.isDark ? 60 : 22),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.currency_exchange_outlined,
              color: AppTheme.textBlack,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.fromCurrency} → ${entry.toCurrency}',
                  style: AppTheme.labelLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  formatDateTimeString(entry.createdAt),
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_fixed(entry.amount)} ${entry.fromCurrency}',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
              ),
              const SizedBox(height: 2),
              Text(
                '${_fixed(entry.convertedAmount)} ${entry.toCurrency}',
                style: AppTheme.labelLarge.copyWith(color: AppColors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
