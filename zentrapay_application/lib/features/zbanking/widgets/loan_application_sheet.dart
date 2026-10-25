import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';

/// Opens the micro-loan application. The form is preceded by what the lender
/// will offer *this* user (KYC level, risk grade, limits); someone who cannot
/// borrow sees exactly what stands in the way instead of a form that fails.
Future<void> showLoanApplicationSheet(BuildContext context) {
  return showAppOverlaySheet<void>(
    context: context,
    minHeightFraction: 0.7,
    maxHeightFraction: 0.95,
    maxWidth: 600,
    builder: (_) => const _LoanApplicationBody(),
  );
}

const _purposes = <String, String>{
  'BUSINESS': 'Business',
  'EDUCATION': 'Education',
  'MEDICAL': 'Medical',
  'RENT': 'Rent',
  'EMERGENCY': 'Emergency',
  'PERSONAL': 'Personal',
  'OTHER': 'Other',
};

const _employmentStatuses = <String, String>{
  'EMPLOYED': 'Employed',
  'SELF_EMPLOYED': 'Self-employed',
  'STUDENT': 'Student',
  'RETIRED': 'Retired',
  'UNEMPLOYED': 'Unemployed',
};

const _relationships = <String>[
  'Spouse',
  'Parent',
  'Sibling',
  'Child',
  'Relative',
  'Friend',
];

class _LoanApplicationBody extends StatefulWidget {
  const _LoanApplicationBody();

  @override
  State<_LoanApplicationBody> createState() => _LoanApplicationBodyState();
}

class _LoanApplicationBodyState extends State<_LoanApplicationBody> {
  LoanEligibility? _eligibility;
  bool _loading = true;
  String? _loadError;

  final _amount = TextEditingController();
  final _employer = TextEditingController();
  final _jobTitle = TextEditingController();
  final _income = TextEditingController();
  final _obligations = TextEditingController();
  final _kinName = TextEditingController();
  final _kinPhone = TextEditingController();

  String? _purpose;
  String? _employment;
  String? _relationship;
  int _term = 3;
  bool _creditConsent = false;
  bool _terms = false;
  bool _submitting = false;
  String? _formError;

  bool get _needsEmployer =>
      _employment == 'EMPLOYED' || _employment == 'SELF_EMPLOYED';

  @override
  void initState() {
    super.initState();
    _loadEligibility();
  }

  @override
  void dispose() {
    for (final c in [
      _amount,
      _employer,
      _jobTitle,
      _income,
      _obligations,
      _kinName,
      _kinPhone,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEligibility() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final result = await LoansRepository.instance.fetchEligibility();
      if (!mounted) return;
      setState(() {
        _eligibility = result;
        _loading = false;
        if (result.maxTermMonths > 0 && _term > result.maxTermMonths) {
          _term = result.maxTermMonths;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = errorMessage(
          e,
          fallback: "We couldn't check your loan eligibility right now.",
        );
      });
    }
  }

  double? get _parsedAmount => double.tryParse(_amount.text.trim());

  /// Same arithmetic as the lender: principal plus simple interest over the term.
  double? get _installment {
    final e = _eligibility;
    final amount = _parsedAmount;
    if (e == null || amount == null || amount <= 0) return null;
    final total = amount + amount * e.interestRate * _term / 12;
    return total / _term;
  }

  String? _validate() {
    final e = _eligibility!;
    final amount = _parsedAmount;
    if (_purpose == null) return 'Choose what the loan is for.';
    if (amount == null || amount <= 0) return 'Enter the amount you need.';
    if (amount < e.minAmount || amount > e.maxAmount) {
      return 'You can borrow between ${_money(e.minAmount, e.currencyCode)} '
          'and ${_money(e.maxAmount, e.currencyCode)}.';
    }
    if (_employment == null) return 'Choose your employment status.';
    if (_needsEmployer && _employer.text.trim().isEmpty) {
      return _employment == 'SELF_EMPLOYED'
          ? 'Enter your business name.'
          : 'Enter your employer.';
    }
    final income = double.tryParse(_income.text.trim());
    if (income == null || income <= 0) return 'Enter your monthly income.';
    final obligations = double.tryParse(
      _obligations.text.trim().isEmpty ? '0' : _obligations.text.trim(),
    );
    if (obligations == null || obligations < 0) {
      return 'Enter your monthly commitments, or 0 if you have none.';
    }
    final installment = _installment;
    if (installment != null && obligations + installment > income * 0.4) {
      return 'This is more than your income can comfortably repay. '
          'Try a smaller amount or a longer term.';
    }
    if (_kinName.text.trim().isEmpty) return "Enter your next of kin's name.";
    if (_relationship == null) return 'Choose your next of kin relationship.';
    if (_kinPhone.text.replaceAll(RegExp(r'[^0-9]'), '').length < 9) {
      return "Enter a valid phone number for your next of kin.";
    }
    if (!_creditConsent) return 'Please allow the credit check to continue.';
    if (!_terms) return 'Please accept the loan terms to continue.';
    return null;
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _formError = problem);
      return;
    }
    setState(() {
      _submitting = true;
      _formError = null;
    });
    try {
      final loan = await LoansRepository.instance.apply(
        LoanApplication(
          amount: _amount.text.trim(),
          currencyCode: _eligibility!.currencyCode,
          termMonths: _term,
          purpose: _purpose!,
          employmentStatus: _employment!,
          employerName: _needsEmployer ? _employer.text.trim() : '',
          jobTitle: _needsEmployer ? _jobTitle.text.trim() : '',
          monthlyIncome: _income.text.trim(),
          monthlyObligations: _obligations.text.trim().isEmpty
              ? '0'
              : _obligations.text.trim(),
          nextOfKinName: _kinName.text.trim(),
          nextOfKinRelationship: _relationship!,
          nextOfKinPhone: _kinPhone.text.trim(),
          creditCheckConsent: _creditConsent,
          termsAccepted: _terms,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ZentraNotifier.success(
        'Application submitted',
        'Your ${_money(double.tryParse(loan.principalAmount) ?? 0, loan.currencyCode)} '
            'loan request is now under review.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _formError = errorMessage(
          e,
          fallback: "We couldn't submit your application. Please try again.",
        );
      });
    }
  }

  static String _money(double value, String currency) {
    final fixed = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
    final parts = fixed.split('.');
    final whole = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => ',',
    );
    return '$currency ${parts.length > 1 ? '$whole.${parts[1]}' : whole}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Micro-loan', style: AppTheme.headlineSmall),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              'Quick, small loans for verified Zentrapay customers.',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (_loading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.brand),
                ),
              )
            else if (_loadError != null)
              _messageCard(
                icon: Icons.cloud_off_outlined,
                title: _loadError!,
                action: TextButton(
                  onPressed: _loadEligibility,
                  child: const Text('Try again'),
                ),
              )
            else ...[
              _offerCard(_eligibility!),
              const SizedBox(height: AppTheme.spacingMd),
              if (_eligibility!.eligible)
                ..._form(_eligibility!)
              else
                _blockers(_eligibility!),
            ],
            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- offer

  Widget _offerCard(LoanEligibility e) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingXs,
            children: [
              _pill(
                Icons.verified_user_outlined,
                'Verification level ${e.kycTier}',
              ),
              _pill(
                Icons.workspace_premium_outlined,
                e.grade == null ? 'No grade yet' : 'Grade ${e.grade}',
              ),
            ],
          ),
          if (e.eligible) ...[
            const SizedBox(height: AppTheme.spacingMd),
            Text('You can borrow', style: AppTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              '${_money(e.minAmount, e.currencyCode)} – '
              '${_money(e.maxAmount, e.currencyCode)}',
              style: AppTheme.headlineSmall.copyWith(color: AppTheme.brand),
            ),
            const SizedBox(height: 2),
            Text(
              'Up to ${e.maxTermMonths} months · '
              '${(e.interestRate * 100).toStringAsFixed(0)}% a year',
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.brand.withAlpha(AppTheme.isDark ? 60 : 24),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textBlack),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.brand,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blockers(LoanEligibility e) {
    return _messageCard(
      icon: Icons.info_outline,
      title: "You can't apply for a loan yet",
      lines: e.requirements,
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    List<String> lines = const [],
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.warningOrange),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(child: Text(title, style: AppTheme.labelLarge)),
            ],
          ),
          for (final line in lines) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Icon(Icons.circle, size: 6, color: AppTheme.textBlack),
                ),
                Expanded(child: Text(line, style: AppTheme.bodySmall)),
              ],
            ),
          ],
          ?action,
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- form

  List<Widget> _form(LoanEligibility e) {
    final installment = _installment;
    return [
      _section('The loan'),
      _dropdown(
        label: 'What is the loan for?',
        value: _purpose,
        items: _purposes,
        onChanged: (v) => setState(() => _purpose = v),
      ),
      _gap,
      AppTextField(
        controller: _amount,
        labelText: 'Amount (${e.currencyCode})',
        hintText:
            '${_money(e.minAmount, e.currencyCode)} – ${_money(e.maxAmount, e.currencyCode)}',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
      ),
      _gap,
      Text(
        'Repay over $_term ${_term == 1 ? 'month' : 'months'}',
        style: AppTheme.bodyMedium,
      ),
      if (e.maxTermMonths > 1)
        Slider(
          value: _term.toDouble(),
          min: 1,
          max: e.maxTermMonths.toDouble(),
          divisions: e.maxTermMonths - 1,
          activeColor: AppTheme.brand,
          label: '$_term',
          onChanged: (v) => setState(() => _term = v.round()),
        ),
      if (installment != null)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: AppTheme.brand.withAlpha(AppTheme.isDark ? 50 : 16),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Text(
            'About ${_money(installment, e.currencyCode)} a month · '
            '${_money(installment * _term, e.currencyCode)} in total',
            style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      _section('Your work and income'),
      _dropdown(
        label: 'Employment status',
        value: _employment,
        items: _employmentStatuses,
        onChanged: (v) => setState(() => _employment = v),
      ),
      if (_needsEmployer) ...[
        _gap,
        AppTextField(
          controller: _employer,
          labelText: _employment == 'SELF_EMPLOYED'
              ? 'Business name'
              : 'Employer',
        ),
        _gap,
        AppTextField(controller: _jobTitle, labelText: 'Job title / trade'),
      ],
      _gap,
      AppTextField(
        controller: _income,
        labelText: 'Monthly income (${e.currencyCode})',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => setState(() {}),
      ),
      _gap,
      AppTextField(
        controller: _obligations,
        labelText: 'Monthly commitments (${e.currencyCode})',
        hintText: 'Rent, other loans, school fees… or 0',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
      _section('Next of kin'),
      AppTextField(controller: _kinName, labelText: 'Full name'),
      _gap,
      _dropdown(
        label: 'Relationship',
        value: _relationship,
        items: {for (final r in _relationships) r: r},
        onChanged: (v) => setState(() => _relationship = v),
      ),
      _gap,
      AppTextField(
        controller: _kinPhone,
        labelText: 'Phone number',
        keyboardType: TextInputType.phone,
      ),
      _section('Consent'),
      CheckboxListTile(
        value: _creditConsent,
        onChanged: (v) => setState(() => _creditConsent = v ?? false),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.brand,
        title: Text(
          'I allow Zentrapay to run a credit check on me.',
          style: AppTheme.bodySmall,
        ),
      ),
      CheckboxListTile(
        value: _terms,
        onChanged: (v) => setState(() => _terms = v ?? false),
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppTheme.brand,
        title: Text(
          'I have read and accept the loan terms, including the interest '
          'and repayment schedule shown above.',
          style: AppTheme.bodySmall,
        ),
      ),
      if (_formError != null) ...[
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          _formError!,
          style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
        ),
      ],
      const SizedBox(height: AppTheme.spacingMd),
      PrimaryButton(
        label: 'Submit application',
        loading: _submitting,
        onPressed: _submit,
      ),
    ];
  }

  static const SizedBox _gap = SizedBox(height: AppTheme.spacingSm);

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: AppTheme.spacingLg, bottom: 8),
    child: Text(title, style: AppTheme.labelLarge),
  );

  Widget _dropdown({
    required String label,
    required String? value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final radius = BorderRadius.circular(AppTheme.radiusMd);
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: AppTheme.surface,
      style: AppTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.bodySmall,
        filled: true,
        fillColor: AppTheme.gray100,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
      ),
      items: [
        for (final entry in items.entries)
          DropdownMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      onChanged: onChanged,
    );
  }
}
