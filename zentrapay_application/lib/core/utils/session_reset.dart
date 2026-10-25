import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/utils/storage_service.dart';
import 'package:zentrapay_application/features/Settings/repository/cache_settings_data.dart';
import 'package:zentrapay_application/features/home/repository/cache_home_data.dart';
import 'package:zentrapay_application/features/payments/repository/cache_payments_data.dart';
import 'package:zentrapay_application/features/profile/repository/cache_profile_data.dart';
import 'package:zentrapay_application/features/zbanking/repository/cache_zbanking_data.dart'
    as zbanking;
import 'package:zentrapay_application/features/zgrow/emergency/emergency_vault.dart';
import 'package:zentrapay_application/features/zgrow/repository/cache_zgrow_data.dart'
    as zgrow;
import 'package:zentrapay_application/features/zinvest/repository/cache_zinvest_data.dart';
import 'package:zentrapay_application/features/zremit/repository/cache_zremit_data.dart';
import 'package:zentrapay_application/features/zvoice/repository/cache_zvoice_data.dart';

/// Forgets everything that belongs to the signed-in user: the token and saved
/// identity, and every in-memory repository cache. The repositories are
/// app-wide singletons that only load once, so without this the next person to
/// log in or register on the same device would still see the previous user's
/// profile, wallets and history.
///
/// Call it on logout, and again right before a new session is stored (login /
/// register) so a stale cache can never leak across accounts.
Future<void> resetUserSession() async {
  await SecureStorageService.deleteToken();
  try {
    await SecureStorageService.clearCustomer();
  } catch (e) {
    debugPrint('Could not clear saved customer data: $e');
  }
  clearUserCaches();
}

/// Empties every user-scoped cache without touching the stored token.
void clearUserCaches() {
  UserProfileRepository.instance.clear();
  UserQRRepository.instance.clear();
  WalletsRepository.instance.clear();
  CardsRepository.instance.clear();
  UserCardsRepository.instance.clear();
  TransactionsRepository.instance.clear();
  NotificationsRepository.instance.clear();
  BillPaymentHistoryRepository.instance.clear();
  ServiceProvidersRepository.instance.clear();
  BillProvidersRepository.instance.clear();
  CountriesRepository.instance.clear();
  CurrenciesRepository.instance.clear();
  ProviderCategoriesRepository.instance.clear();

  RatesRepository.instance.clear();
  ConverterHistoryRepository.instance.clear();

  SecuritySettingsRepository.instance.clear();
  FraudAlertsRepository.instance.clear();
  LoginHistoryRepository.instance.clear();

  zbanking.BankAccountsRepository.instance.clear();
  zbanking.LoansRepository.instance.clear();
  zbanking.BudgetRepository.instance.clear();
  zbanking.BankingInsightsRepository.instance.clear();
  zbanking.SavingsRepository.instance.clear();

  zgrow.ChallengesRepository.instance.clear();
  zgrow.UserChallengesRepository.instance.clear();
  zgrow.LiteracyRepository.instance.clear();
  zgrow.RewardsRepository.instance.clear();
  zgrow.TutorialsRepository.instance.clear();
  zgrow.GamificationSettingsRepository.instance.clear();
  zgrow.SavingsRepository.instance.clear();

  InvestmentsRepository.instance.clear();
  LiquidityProfileRepository.instance.clear();
  LiquidityTrendRepository.instance.clear();
  InvestmentRisksRepository.instance.clear();
  InvestmentAlertsRepository.instance.clear();

  RemittanceHistoryRepository.instance.clear();
  VoiceCommandHistoryRepository.instance.clear();
  VoiceFraudAlertsRepository.instance.clear();

  EmergencyVault.instance.reset();
}
