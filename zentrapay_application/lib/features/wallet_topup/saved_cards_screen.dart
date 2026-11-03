import 'package:flutter/material.dart';
import 'package:zentrapay_application/core/models/saved_card.dart';
import 'package:zentrapay_application/core/theme/app_theme.dart';
import 'package:zentrapay_application/core/theme/section_header.dart';
import 'package:zentrapay_application/core/utils/notifier.dart';
import 'package:zentrapay_application/features/wallet_topup/saved_cards_repository.dart';
import 'package:zentrapay_application/features/wallet_topup/topup_screen.dart';

/// The cards the user kept after paying a top-up by card. A card is added by ticking "Save my card" on
/// the top-up sheet; here it can be made the default or removed.
class SavedCardsScreen extends StatefulWidget {
  const SavedCardsScreen({super.key});

  @override
  State<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  final _repo = SavedCardsRepository.instance;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _repo.ensureLoaded(forceRefresh: true).catchError((_) {});
  }

  Future<void> _run(String id, Future<void> Function() action, String done) async {
    setState(() => _busyId = id);
    try {
      await action();
      ZentraNotifier.success('Saved cards', done);
    } catch (e) {
      ZentraNotifier.error(
        'Saved cards',
        errorMessage(e, fallback: 'That did not work. Please try again.'),
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _confirmRemove(SavedCard card) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove card?'),
        content: Text(
          '${card.label} will be forgotten. You can save it again the next time you pay with it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _run(card.id, () => _repo.remove(card.id), 'Card removed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SectionAppBar(),
      backgroundColor: AppTheme.primaryPink,
      body: ListenableBuilder(
        listenable: _repo,
        builder: (context, _) {
          return SectionScrollView(
            onRefresh: () => _repo.ensureLoaded(forceRefresh: true),
            header: SectionHeader(
              title: 'Saved cards',
              subtitle: 'Top up in one tap with a card you already used',
              icon: Icons.credit_card_rounded,
              showBack: true,
              sheetColor: AppTheme.gray50,
            ),
            sheet: SectionSheet(
              color: AppTheme.gray50,
              topPadding: AppTheme.spacingLg,
              child: _body(),
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_repo.isLoading && !_repo.isLoaded) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final cards = _repo.cards;
    if (cards.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
        child: Column(
          children: [
            Icon(Icons.credit_card_off_outlined, size: 48, color: AppTheme.gray500),
            const SizedBox(height: AppTheme.spacingMd),
            Text('No saved cards yet', style: AppTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Pay a top-up by card and tick "Save my card" - it will show up here.\n'
              'Card numbers are entered on the payment provider\'s page and never reach ZentraPay.',
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.gray500),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            ElevatedButton(
              onPressed: () => showTopupSheet(context),
              child: const Text('Top up now'),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final card in cards) _cardTile(card)],
    );
  }

  Widget _cardTile(SavedCard card) {
    final busy = _busyId == card.id;
    final details = [
      if (card.bank.isNotEmpty) card.bank,
      if (card.expiry.isNotEmpty) card.expired ? 'Expired ${card.expiry}' : 'Expires ${card.expiry}',
    ].join('  •  ');
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: card.isDefault ? AppTheme.primaryPink : AppTheme.gray300),
      ),
      child: Row(
        children: [
          Icon(Icons.credit_card_rounded, color: AppTheme.textBlack),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(card.label, style: AppTheme.labelLarge, overflow: TextOverflow.ellipsis),
                    ),
                    if (card.isDefault) ...[
                      const SizedBox(width: AppTheme.spacingSm),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Default', style: AppTheme.bodySmall),
                      ),
                    ],
                  ],
                ),
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: AppTheme.bodySmall.copyWith(
                      color: card.expired ? AppTheme.errorRed : AppTheme.gray500,
                    ),
                  ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
          else
            PopupMenuButton<String>(
              color: AppTheme.gray100,
              onSelected: (value) {
                if (value == 'default') {
                  _run(card.id, () => _repo.makeDefault(card.id), 'Default card updated.');
                } else if (value == 'remove') {
                  _confirmRemove(card);
                }
              },
              itemBuilder: (_) => [
                if (!card.isDefault && !card.expired)
                  const PopupMenuItem(value: 'default', child: Text('Make default')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
        ],
      ),
    );
  }
}
