import 'package:flutter/material.dart';

import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/common_widgets.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profile_data.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';

/// Opens the bank picker overlay and returns the linked account, or null if
/// the user dismissed the flow.
///
/// The picker fetches the public bank catalog (`GET /api/reference/banks`) and
/// lets the user search/pick a bank. Selecting one pops a *second* overlay with
/// the actual linking form (account number + first/last name + optional label
/// + primary toggle) — the form never appears inline in the picker. On success the repository
/// refreshes its snapshot so the ZBank header and the horizontal strip pick the
/// new account up.
Future<BankAccounts?> showLinkBankSheet(BuildContext context) {
  return showAppOverlaySheet<BankAccounts>(
    context: context,
    minHeightFraction: 0.7,
    maxHeightFraction: 0.95,
    // Full width on phones, centred and capped at 600 on tablets/desktop so the
    // picker doesn't stretch into an unreadable wide band.
    maxWidth: 600,
    builder: (_) => const _LinkBankSheetBody(),
  );
}

class _LinkBankSheetBody extends StatefulWidget {
  const _LinkBankSheetBody();

  @override
  State<_LinkBankSheetBody> createState() => _LinkBankSheetBodyState();
}

class _LinkBankSheetBodyState extends State<_LinkBankSheetBody> {
  final _searchController = TextEditingController();

  List<BankCatalogEntry> _banks = const [];
  BankCatalogEntry? _selected;
  bool _loadingBanks = true;

  /// ISO alpha-2 country of the signed-in user (e.g. `GH`). Banks are only
  /// listed for this country — the backend filters on `?country=`, and we
  /// re-check client-side in case the profile hasn't resolved yet.
  String? _countryCode;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBanks({String query = ''}) async {
    setState(() => _loadingBanks = true);
    try {
      // Best effort: the bank catalog is a *public* endpoint, so a failed or
      // slow profile fetch must not take the whole picker down with it. On
      // error we keep whatever country code we already have (or none) and
      // still load the catalog below.
      try {
        // The profile cache is shared app-wide and may already be populated by
        // Home/Profile, so this is usually a cache hit rather than a network call.
        final profile = await UserProfileRepository.instance.ensureLoaded();
        final country = profile?.user.countryCode.trim();
        if (!mounted) return;
        setState(
          () => _countryCode = (country?.isNotEmpty ?? false) ? country : null,
        );
      } catch (_) {
        // Keep the previous/absent country code — the catalog still loads.
      }
      if (!mounted) return;

      final banks = await BankAccountsRepository.instance.fetchBankCatalog(
        query: query,
        country: _countryCode,
      );
      if (!mounted) return;
      // Re-assert the country filter client-side: the backend already filters,
      // but this keeps the list correct if the catalog ever returns a
      // neighbouring row (or the country code casing differs).
      final filtered = banks
          .where((b) => _matchesCountry(b.countryCode, _countryCode))
          .toList();
      setState(() {
        _banks = filtered;
        _loadingBanks = false;
        // Drop the selection if it disappeared from the filtered results.
        if (_selected != null &&
            !filtered.any((b) => b.bankId == _selected!.bankId)) {
          _selected = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingBanks = false;
        debugPrint('Could not load banks. Try searching again.');
      });
    }
  }

  /// Case-insensitive alpha-2 country match. An unknown user country (null)
  /// keeps every bank rather than showing an empty, unexplainable list.
  static bool _matchesCountry(String bankCountry, String? userCountry) {
    if (userCountry == null || userCountry.isEmpty) return true;
    if (bankCountry.trim().isEmpty) return true;
    return bankCountry.trim().toUpperCase() == userCountry.toUpperCase();
  }

  /// Clears the field and reloads the unfiltered catalog. `setState` is what
  /// hides the clear button, since the controller alone won't rebuild.
  void _clearSearch() {
    setState(() => _searchController.clear());
    _loadBanks();
  }

  /// Pops the account-details form as a second overlay on top of this picker.
  ///
  /// The form only exists after a bank is picked (it lives in its own route),
  /// and it carries its own keyboard handling: `showAppOverlaySheet` resizes
  /// against the height left above the keyboard and lifts the sheet by the
  /// inset, while the form scrolls the focused field into view inside that
  /// space. If a bank gets linked, this picker closes too so
  /// `showLinkBankSheet` resolves with the new account in one gesture.
  Future<void> _openLinkForm(BankCatalogEntry bank) async {
    final linked = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      barrierColor: AppTheme.textBlack.withAlpha(20),
      // Compact: only as tall as the form needs, still capped so the keyboard
      // (which shrinks the sheet via the helper) can never cover the button.
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          15.0,
          15.0,
          15.0,
          15.0 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _LinkBankForm(bank: bank, context: context),
      ),
    );
    if (!mounted || linked == null) return;
    Navigator.of(context).pop(linked);
  }

  @override
  Widget build(BuildContext context) {
    // No `bottom: viewInsets` padding here: `showAppOverlaySheet` already pads
    // the whole sheet by the keyboard inset and sizes itself against the height
    // left above the keyboard — adding it again would double-lift the content
    // and leave a huge gap under the last row.
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingMd,
        right: AppTheme.spacingMd,
      ),
      // The helper wraps this body in an Expanded, so LayoutBuilder sees the
      // sheet's *tight* inner height — which is what lets the list stop short
      // and keep the reserved 100px gap visible without any scrolling.
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Fixed content above the list (title + subtitle + search + gaps),
          // and the required space of 100 below it.
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Link a bank', style: AppTheme.headlineSmall),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Pick a bank, then confirm the account you want to connect.',
                  style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                _buildSearchField(),
                const SizedBox(height: AppTheme.spacingMd),
                // Height-budgeted (see `listMax`): the list stops short of the
                // sheet bottom so the reserved 100px gap below it always lands
                // within view — a ListView fills whatever max height it's given,
                // which previously pushed the gap below the fold.
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width,
                    maxHeight: MediaQuery.of(context).size.height * 0.95,
                  ),
                  child: _buildBankList(),
                ),
                // The account form is NOT rendered here anymore — picking a bank
                // pops it as its own overlay (`_openLinkForm`).
                SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: (value) => _loadBanks(query: value),
      decoration: InputDecoration(
        hintText: 'Search banks',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close),
                onPressed: _clearSearch,
              ),
        filled: true,
        fillColor: AppTheme.gray100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildBankList() {
    if (_loadingBanks) {
      return Center(child: CircularProgressIndicator(color: AppTheme.brand));
    }
    if (_banks.isEmpty) {
      return Center(
        child: Text(
          _countryCode == null
              ? 'No banks match your search.'
              : 'No banks available in $_countryCode yet.',
          textAlign: TextAlign.center,
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.gray500),
        ),
      );
    }

    return ListView.separated(
      itemCount: _banks.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTheme.spacingSm),
      itemBuilder: (context, index) {
        final bank = _banks[index];
        final selected = _selected?.bankId == bank.bankId;
        return InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () {
            setState(() {
              _selected = bank;
            });
            // Selecting a bank opens the linking form as an overlay — the
            // form only shows once there's a bank to link.
            _openLinkForm(bank);
          },
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: selected ? AppTheme.brand.withAlpha(15) : AppTheme.gray50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(
                color: selected ? AppTheme.brand : AppTheme.dividerColor,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.brand.withAlpha(25),
                  child: Text(
                    bank.bankName.isEmpty
                        ? '?'
                        : bank.bankName.characters.first.toUpperCase(),
                    style: AppTheme.labelLarge.copyWith(color: AppTheme.brand),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank.bankName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.labelLarge,
                      ),
                      Text(
                        [
                          if (bank.countryCode.isNotEmpty) bank.countryCode,
                          if (bank.currencyCode.isNotEmpty) bank.currencyCode,
                        ].join(' · '),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.gray500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selected ? AppTheme.brand : AppTheme.gray300,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Second-stage overlay: the actual linking form (account number, account
/// holder first/last name, optional label, primary toggle). Opened by the
/// picker when a bank is tapped and it returns the linked account on success,
/// or null when dismissed.
///
/// Keyboard behaviour comes from `showAppOverlaySheet`, which resizes the
/// sheet against the height left above the keyboard and lifts it by the inset —
/// this body only scrolls the focused field into view inside that space.
class _LinkBankForm extends StatefulWidget {
  const _LinkBankForm({required this.bank, required context});

  final BankCatalogEntry bank;

  @override
  State<_LinkBankForm> createState() => _LinkBankFormState();
}

class _LinkBankFormState extends State<_LinkBankForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _accountController = TextEditingController();
  final _labelController = TextEditingController();

  // Driving the scroll view from the field focus nodes is what makes the form
  // follow the keyboard: without it, tapping a field on a short screen leaves
  // it under the keyboard with no way to see what you type.
  final _scrollController = ScrollController();
  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _accountFocus = FocusNode();
  final _labelFocus = FocusNode();

  bool _submitting = false;
  bool _makePrimary = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Scroll the focused field into view once the keyboard has finished
    // animating, otherwise the scroll races the inset animation.
    _firstNameFocus.addListener(() => _revealFocusedField(_firstNameFocus));
    _lastNameFocus.addListener(() => _revealFocusedField(_lastNameFocus));
    _accountFocus.addListener(() => _revealFocusedField(_accountFocus));
    _labelFocus.addListener(() => _revealFocusedField(_labelFocus));
  }

  /// Brings the just-focused field into view by scrolling to the bottom of the
  /// form (the action button and error always sit last).
  void _revealFocusedField(FocusNode node) {
    if (!node.hasFocus) return;
    // Wait a frame for the keyboard inset to be applied before scrolling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      if (max <= 0) return; // Everything already fits — nothing to reveal.
      _scrollController.animateTo(
        max,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _accountController.dispose();
    _labelController.dispose();
    _scrollController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _accountFocus.dispose();
    _labelFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final accountNumber = _accountController.text.trim();
    final linkLabel = _labelController.text.trim();
    if (firstName.isEmpty) {
      setState(() => _error = 'Enter the first name on the bank account.');
      _firstNameFocus.requestFocus();
      return;
    }
    if (lastName.isEmpty) {
      setState(() => _error = 'Enter the last name on the bank account.');
      _lastNameFocus.requestFocus();
      return;
    }
    if (accountNumber.replaceAll(RegExp(r'[^0-9]'), '').length < 4) {
      setState(
        () => _error = 'Enter at least the last 4 digits of the account.',
      );
      _accountFocus.requestFocus();
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final linked = await BankAccountsRepository.instance.linkBank(
        bankId: widget.bank.bankId,
        accountNumber: accountNumber,
        firstName: firstName,
        lastName: lastName,
        linkLabel: linkLabel,
        primary: _makePrimary,
      );
      if (!mounted) return;
      // Success: hand the account to the picker, which closes the whole flow.
      Navigator.of(context).pop(linked);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _friendlyError(e);
      });
    }
  }

  /// Turns the Dio/validation error into something worth showing. Only the
  /// API's user-facing message is ever shown — nothing about providers,
  /// transport or how the system is built.
  String _friendlyError(Object e) {
    final message = errorMessage(
      e,
      fallback: "We couldn't link that bank. Please try again.",
    );
    final lower = message.toLowerCase();
    if (lower.contains('already linked')) {
      return 'You have already linked this bank.';
    }
    if (lower.contains('too short')) {
      return 'That account number looks too short.';
    }
    if (lower.contains('not found')) {
      return 'That bank is unavailable. Try another.';
    }
    return message;
  }

  Widget _nameField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required ValueChanged<String> onSubmitted,
    bool autofocus = false,
  }) {
    final radius = BorderRadius.circular(AppTheme.radiusMd);
    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTheme.bodySmall,
        filled: true,
        fillColor: AppTheme.gray100,
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: AppTheme.brand, width: 1.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bank = widget.bank;
    // Horizontal only — the sheet's *bottom* keyboard lift comes from
    // `showAppOverlaySheet`; padding `viewInsets` here too would double it.
    final radius = BorderRadius.circular(AppTheme.radiusMd);
    return SingleChildScrollView(
      controller: _scrollController,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Link ${bank.bankName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.labelLarge,
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: Icon(Icons.close, size: 20, color: AppTheme.textBlack),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.primaryPink.withAlpha(10),
              border: Border.all(color: AppTheme.primaryPink, width: 1.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Note:",
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textBlack,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "For 'First name' and 'Last name', enter the name and surname associated with the bank account!",
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textBlack,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Column(
            spacing: AppTheme.spacingMd,
            children: [
              Row(
                spacing: AppTheme.spacingSm,
                children: [
                  Expanded(
                    child: _nameField(
                      controller: _firstNameController,
                      focusNode: _firstNameFocus,
                      label: 'First name',
                      autofocus: true,
                      onSubmitted: (_) => _lastNameFocus.requestFocus(),
                    ),
                  ),
                  Expanded(
                    child: _nameField(
                      controller: _lastNameController,
                      focusNode: _lastNameFocus,
                      label: 'Last name',
                      onSubmitted: (_) => _accountFocus.requestFocus(),
                    ),
                  ),
                ],
              ),
              TextField(
                controller: _accountController,
                focusNode: _accountFocus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _labelFocus.requestFocus(),
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(color: AppTheme.brand, width: 1.5),
                  ),
                  labelText: 'Account number',
                  labelStyle: AppTheme.bodySmall,
                  hintText: 'At least the last 4 digits',
                  filled: true,
                  fillColor: AppTheme.gray100,
                  border: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide.none,
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(
                      color: AppTheme.primaryPink,
                      width: 2,
                    ),
                  ),
                ),
              ),

              TextField(
                controller: _labelController,
                focusNode: _labelFocus,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  focusedBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(color: AppTheme.brand, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(
                      color: AppTheme.primaryPink,
                      width: 2,
                    ),
                  ),
                  labelText: 'Label (optional)',
                  labelStyle: AppTheme.bodySmall,
                  hintText: 'e.g. Salary, Rent Fund',
                  filled: true,
                  fillColor: AppTheme.gray100,
                  border: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          CheckboxListTile(
            value: _makePrimary,
            onChanged: (value) => setState(() => _makePrimary = value ?? false),
            contentPadding: EdgeInsets.zero,
            activeColor: AppTheme.brand,
            title: Text(
              'Make this my primary account',
              style: AppTheme.bodySmall,
            ),
          ),
          // AppTheme.brand (primary pink) is the project-wide button colour.
          PrimaryButton(
            label: _submitting ? 'Linking...' : 'Link bank',
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
            backgroundColor: AppTheme.brand,
            foregroundColor: AppTheme.primaryWhite,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              _error!,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.errorRed),
            ),
          ],
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ),
    );
  }
}
