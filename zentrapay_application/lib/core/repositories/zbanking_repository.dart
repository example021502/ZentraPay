import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/zbanking.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';

class SavingsRepository extends CachedListResource<SavingsAccount> {
  SavingsRepository._();
  static final SavingsRepository instance = SavingsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<SavingsAccount>> fetch() async {
    final response = await _dio.get('/api/zbanking/savings');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => SavingsAccount.fromJson(e))
        .toList();
  }

  Future<SavingsAccount> create({
    required String savingsName,
    required String currencyCode,
    required String initialDeposit,
    String? targetAmount,
    String? targetDate,
    String? description,
  }) async {
    final response = await _dio.post(
      '/api/zbanking/savings',
      data: {
        'savingsName': savingsName,
        'currencyCode': currencyCode,
        'initialDeposit': initialDeposit,
        'targetAmount': ?targetAmount,
        'targetDate': ?targetDate,
        'description': ?description,
      },
    );
    final account = SavingsAccount.fromJson(response.data['data']);
    addItem(account);
    return account;
  }

  Future<SavingsAccount> deposit(String savingsId, String amount) async {
    final response = await _dio.post(
      '/api/zbanking/savings/$savingsId/deposit',
      data: {'amount': amount},
    );
    final account = SavingsAccount.fromJson(response.data['data']);
    replaceItem((s) => s.savingsId == savingsId, account);
    return account;
  }

  Future<SavingsAccount> withdraw(String savingsId, String amount) async {
    final response = await _dio.post(
      '/api/zbanking/savings/$savingsId/withdraw',
      data: {'amount': amount},
    );
    final account = SavingsAccount.fromJson(response.data['data']);
    replaceItem((s) => s.savingsId == savingsId, account);
    return account;
  }
}

class LoansRepository extends CachedListResource<Loan> {
  LoansRepository._();
  static final LoansRepository instance = LoansRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<Loan>> fetch() async {
    final response = await _dio.get('/api/zbanking/loans');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => Loan.fromJson(e))
        .toList();
  }

  Future<Loan> apply({
    required String amount,
    required String currencyCode,
    required int termMonths,
  }) async {
    final response = await _dio.post(
      '/api/zbanking/loans/apply',
      data: {
        'amount': amount,
        'currencyCode': currencyCode,
        'termMonths': termMonths,
      },
    );
    final loan = Loan.fromJson(response.data['data']);
    addItem(loan);
    return loan;
  }

  Future<Loan> repay(String loanId, String amount) async {
    final response = await _dio.post(
      '/api/zbanking/loans/$loanId/repay',
      data: {'amount': amount},
    );
    final loan = Loan.fromJson(response.data['data']);
    replaceItem((l) => l.loanId == loanId, loan);
    return loan;
  }
}

class BudgetRepository extends CachedResource<BudgetSummary> {
  BudgetRepository._();
  static final BudgetRepository instance = BudgetRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<BudgetSummary> fetch() async {
    final response = await _dio.get('/api/zbanking/budget');
    return BudgetSummary.fromJson(response.data['data']);
  }

  Future<BudgetSummary> setMonthlyLimit(String monthlyLimit) async {
    final response = await _dio.put(
      '/api/zbanking/budget',
      data: {'monthlyLimit': monthlyLimit},
    );
    final summary = BudgetSummary.fromJson(response.data['data']);
    setData(summary);
    return summary;
  }
}

class BankingInsightsRepository extends CachedResource<BankingInsights> {
  BankingInsightsRepository._();
  static final BankingInsightsRepository instance =
      BankingInsightsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<BankingInsights> fetch() async {
    final response = await _dio.get('/api/zbanking/insights');
    return BankingInsights.fromJson(response.data['data']);
  }
}
