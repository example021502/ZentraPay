import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/features/Settings/repository/cache_settings_data.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/payments/repository/cache_payments_data.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profile_data.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart';
import 'package:zentrapay_application/features/zremit/repository/cache_zremit_data.dart';
import 'package:zentrapay_application/features/zvoice/repository/cache_zvoice_data.dart';

/// Pull-to-refresh for the whole application: asks every cached repository to
/// reload from the backend. Each one is awaited on its own, so a section that
/// fails (offline, 5xx) never stops the others from refreshing, and nothing is
/// thrown to the caller - the screens show whatever each repository holds.
Future<void> refreshWholeApp() async {
  final tasks = <String, Future<void> Function()>{
    'wallets': () => WalletsRepository.instance.refresh(),
    'profile': () => UserProfileRepository.instance.refresh(),
    'transactions': () =>
        TransactionsRepository.instance.ensureLoaded(forceRefresh: true),
    'notifications': () =>
        NotificationsRepository.instance.ensureLoaded(forceRefresh: true),
    'billHistory': () =>
        BillPaymentHistoryRepository.instance.ensureLoaded(forceRefresh: true),
    'cards': () => CardsRepository.instance.ensureLoaded(forceRefresh: true),
    'userCards': () =>
        UserCardsRepository.instance.ensureLoaded(forceRefresh: true),
    'serviceProviders': () =>
        ServiceProvidersRepository.instance.ensureLoaded(forceRefresh: true),
    'billProviders': () =>
        BillProvidersRepository.instance.ensureLoaded(forceRefresh: true),
    'countries': () =>
        CountriesRepository.instance.ensureLoaded(forceRefresh: true),
    'currencies': () =>
        CurrenciesRepository.instance.ensureLoaded(forceRefresh: true),
    'rates': () => RatesRepository.instance.ensureLoaded(forceRefresh: true),
    'bankAccounts': () => BankAccountsRepository.instance.refresh(),
    'loans': () => LoansRepository.instance.ensureLoaded(forceRefresh: true),
    'budget': () => BudgetRepository.instance.ensureLoaded(forceRefresh: true),
    'bankingInsights': () =>
        BankingInsightsRepository.instance.ensureLoaded(forceRefresh: true),
    'securitySettings': () =>
        SecuritySettingsRepository.instance.ensureLoaded(forceRefresh: true),
    'challenges': () =>
        ChallengesRepository.instance.ensureLoaded(forceRefresh: true),
    'userChallenges': () =>
        UserChallengesRepository.instance.ensureLoaded(forceRefresh: true),
    'rewards': () =>
        RewardsRepository.instance.ensureLoaded(forceRefresh: true),
    'tutorials': () =>
        TutorialsRepository.instance.ensureLoaded(forceRefresh: true),
    'remittances': () =>
        RemittanceHistoryRepository.instance.ensureLoaded(forceRefresh: true),
    'voiceHistory': () =>
        VoiceCommandHistoryRepository.instance.ensureLoaded(forceRefresh: true),
  };

  await Future.wait(
    tasks.entries.map((entry) async {
      try {
        await entry.value();
      } catch (e) {
        debugPrint('Refresh of ${entry.key} failed: $e');
      }
    }),
  );
}
