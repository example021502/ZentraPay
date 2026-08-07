class SavingsAccount {
  final String savingsId;
  final String savingsName;
  final String currencyCode;
  final String balance;
  final String? targetAmount;
  final String? targetDate;
  final String status;

  SavingsAccount({
    required this.savingsId,
    required this.savingsName,
    required this.currencyCode,
    required this.balance,
    this.targetAmount,
    this.targetDate,
    required this.status,
  });

  factory SavingsAccount.fromJson(Map<String, dynamic> json) =>
      SavingsAccount(
        savingsId: json['savingsId'] ?? '',
        savingsName: json['savingsName'] ?? '',
        currencyCode: json['currencyCode'] ?? '',
        balance: (json['balance'] ?? '0').toString(),
        targetAmount: json['targetAmount']?.toString(),
        targetDate: json['targetDate'],
        status: json['status'] ?? 'ACTIVE',
      );
}

class Loan {
  final String loanId;
  final String principalAmount;
  final String interestRate;
  final int termMonths;
  final String outstandingBalance;
  final String status;
  final String? dueDate;

  Loan({
    required this.loanId,
    required this.principalAmount,
    required this.interestRate,
    required this.termMonths,
    required this.outstandingBalance,
    required this.status,
    this.dueDate,
  });

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
    loanId: json['loanId'] ?? '',
    principalAmount: (json['principalAmount'] ?? '0').toString(),
    interestRate: (json['interestRate'] ?? '0').toString(),
    termMonths: json['termMonths'] ?? 0,
    outstandingBalance: (json['outstandingBalance'] ?? '0').toString(),
    status: json['status'] ?? 'PENDING',
    dueDate: json['dueDate'],
  );
}

class BudgetSummary {
  final String monthlyLimit;
  final String spentThisMonth;
  final String remaining;

  BudgetSummary({
    required this.monthlyLimit,
    required this.spentThisMonth,
    required this.remaining,
  });

  factory BudgetSummary.fromJson(Map<String, dynamic> json) => BudgetSummary(
    monthlyLimit: (json['monthlyLimit'] ?? '0').toString(),
    spentThisMonth: (json['spentThisMonth'] ?? '0').toString(),
    remaining: (json['remaining'] ?? '0').toString(),
  );
}

class SpendCategory {
  final String categoryCode;
  final String amount;

  SpendCategory({required this.categoryCode, required this.amount});

  factory SpendCategory.fromJson(Map<String, dynamic> json) => SpendCategory(
    categoryCode: json['categoryCode'] ?? '',
    amount: (json['amount'] ?? '0').toString(),
  );
}

class BankingInsights {
  final String monthlySpend;
  final String monthlyIncome;
  final List<SpendCategory> topCategories;

  BankingInsights({
    required this.monthlySpend,
    required this.monthlyIncome,
    required this.topCategories,
  });

  factory BankingInsights.fromJson(Map<String, dynamic> json) =>
      BankingInsights(
        monthlySpend: (json['monthlySpend'] ?? '0').toString(),
        monthlyIncome: (json['monthlyIncome'] ?? '0').toString(),
        topCategories: ((json['topCategories'] as List?) ?? [])
            .map((e) => SpendCategory.fromJson(e))
            .toList(),
      );
}
