/*
* BANK ACCOUNTS DATA STRUCTURE
* */
class BankAccounts {
  final String bankId;
  final String bankName;
  final String bankCode;
  final double balance;
  final String lastDigits;
  final String countryCode;
  final String currencyCode;
  final DateTime createdAt;

  BankAccounts({
    required this.bankId,
    required this.bankName,
    required this.bankCode,
    required this.balance,
    required this.lastDigits,
    required this.countryCode,
    required this.currencyCode,
    required this.createdAt,
  });

  factory BankAccounts.fromJson(Map<String, dynamic> json) => BankAccounts(
    bankId: (json['bankId'] ?? '').toString(),
    bankName: json['bankName'] ?? '',
    bankCode: json['bankCode'] ?? '',
    // Backend AccountsDTO.balance is BigDecimal → JSON number; convert to double.
    balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    lastDigits: json['lastDigits'] ?? '',
    countryCode: json['countryCode'] ?? '',
    currencyCode: json['currencyCode'] ?? '',
    createdAt: json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
        : DateTime.now(),
  );
}

/*
* CARDS DATA STRUCTURE
* */
class Cards {
  final String cardId;
  final String cardName;
  final String cardCode;
  final double balance;
  final String lastDigits;
  final String countryCode;
  final String currencyCode;
  final DateTime createdAt;

  Cards({
    required this.cardId,
    required this.cardName,
    required this.cardCode,
    required this.balance,
    required this.lastDigits,
    required this.countryCode,
    required this.currencyCode,
    required this.createdAt,
  });

  factory Cards.fromJson(Map<String, dynamic> json) => Cards(
    cardId: (json['cardId'] ?? '').toString(),
    cardName: json['cardName'] ?? '',
    cardCode: json['cardCode'] ?? '',
    // Backend AccountsDTO.balance is BigDecimal → JSON number; convert to double.
    balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    lastDigits: json['lastDigits'] ?? '',
    countryCode: json['countryCode'] ?? '',
    currencyCode: json['currencyCode'] ?? '',
    createdAt: json['createdAt'] != null
        ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
        : DateTime.now(),
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

/// A ZBank Lite savings goal — mirrors API_CONTRACT.md §13
/// (`GET /api/zbanking/savings` → {savingsId, savingsName, currencyCode,
/// balance, targetAmount, targetDate, status}). `balance` is a decimal
/// number on the wire (BigDecimal); `targetAmount`/`targetDate` are optional.
class SavingsAccount {
  final String savingsId;
  final String savingsName;
  final String currencyCode;
  final double balance;
  final double? targetAmount;
  final DateTime? targetDate;
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

  factory SavingsAccount.fromJson(Map<String, dynamic> json) => SavingsAccount(
    savingsId: (json['savingsId'] ?? '').toString(),
    savingsName: json['savingsName'] ?? '',
    currencyCode: json['currencyCode'] ?? '',
    balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    targetAmount: (json['targetAmount'] as num?)?.toDouble(),
    targetDate: json['targetDate'] != null
        ? (DateTime.tryParse(json['targetDate'].toString()) ?? DateTime.now())
        : null,
    status: json['status'] ?? '',
  );
}
