/*
* BANK ACCOUNTS DATA STRUCTURE
* */
/// A single bank account linked to the user (ZBank Lite).
///
/// Maps to the backend `UserAccountsDTO` from `GET /api/zbanking/userAccounts`,
/// which joins the user's `user_bank` link rows with the read-only `banks`
/// catalog. Two ids travel with it:
/// - [userBankId] identifies the *link* row — that's what the promote/unlink
///   endpoints take, NOT [bankId] (the shared catalog id).
/// - [isPrimary] marks the one account shown in the ZBank header.
/// - [displayName] is the user-facing name: the link label when set, else the
///   catalog bank name.
class BankAccounts {
  final String userBankId;
  final String userId;
  final String bankId;
  final String bankName;
  final String bankCode;
  final double balance;
  final String lastDigits;
  final String countryCode;
  final String currencyCode;
  final String? linkLabel;
  final bool isPrimary;
  final String connectionStatus;
  final DateTime linkedAt;

  BankAccounts({
    required this.userBankId,
    required this.bankId,
    required this.bankName,
    required this.bankCode,
    required this.balance,
    required this.lastDigits,
    required this.countryCode,
    required this.currencyCode,
    this.userId = '',
    this.linkLabel,
    this.isPrimary = false,
    this.connectionStatus = 'active',
    DateTime? linkedAt,
  }) : linkedAt = linkedAt ?? DateTime.now();

  /// Name to show in the UI: the user's own label wins, else the bank name.
  String get displayName =>
      (linkLabel?.trim().isNotEmpty ?? false) ? linkLabel!.trim() : bankName;

  /// Masked account number for the card face, e.g. `•••• •••• •••• 4821`.
  String get maskedNumber =>
      lastDigits.isEmpty ? '•••• •••• •••• ••••' : '•••• •••• •••• $lastDigits';

  /// `GHS 1,240.00` — currency-qualified balance for the card face.
  String get formattedBalance {
    final code = currencyCode.isEmpty ? 'GHS' : currencyCode;
    return '$code ${balance.toStringAsFixed(2)}';
  }

  factory BankAccounts.fromJson(Map<String, dynamic> json) => BankAccounts(
    userBankId: (json['userBankId'] ?? '').toString(),
    userId: (json['userId'] ?? '').toString(),
    bankId: (json['bankId'] ?? '').toString(),
    bankName: json['bankName'] ?? '',
    bankCode: json['bankCode'] ?? '',
    // Backend balance is BigDecimal → JSON number; convert to double.
    balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    lastDigits: (json['lastDigits'] ?? '').toString(),
    countryCode: json['countryCode'] ?? '',
    currencyCode: json['currencyCode'] ?? '',
    linkLabel: json['linkLabel'] as String?,
    // DTO field is `primary`, not `isPrimary` — keep the wire name here.
    isPrimary: json['primary'] == true,
    connectionStatus: json['connectionStatus'] ?? 'active',
    linkedAt: json['linkedAt'] != null
        ? (DateTime.tryParse(json['linkedAt'].toString()) ?? DateTime.now())
        : DateTime.now(),
  );

  /// Copy used for optimistic UI (e.g. flipping [isPrimary] right after the
  /// promote call so the header re-renders before the refetch lands).
  BankAccounts copyWith({
    String? userBankId,
    String? userId,
    String? bankId,
    String? bankName,
    String? bankCode,
    double? balance,
    String? lastDigits,
    String? countryCode,
    String? currencyCode,
    String? linkLabel,
    bool? isPrimary,
    String? connectionStatus,
    DateTime? linkedAt,
  }) => BankAccounts(
    userBankId: userBankId ?? this.userBankId,
    userId: userId ?? this.userId,
    bankId: bankId ?? this.bankId,
    bankName: bankName ?? this.bankName,
    bankCode: bankCode ?? this.bankCode,
    balance: balance ?? this.balance,
    lastDigits: lastDigits ?? this.lastDigits,
    countryCode: countryCode ?? this.countryCode,
    currencyCode: currencyCode ?? this.currencyCode,
    linkLabel: linkLabel ?? this.linkLabel,
    isPrimary: isPrimary ?? this.isPrimary,
    connectionStatus: connectionStatus ?? this.connectionStatus,
    linkedAt: linkedAt ?? this.linkedAt,
  );
}

/// The user's linked bank accounts as one snapshot: the single primary account
/// (ZBank header) plus every account (bottom horizontal strip).
class BankAccountsSnapshot {
  final BankAccounts? primary;
  final List<BankAccounts> accounts;

  const BankAccountsSnapshot({this.primary, this.accounts = const []});

  static const BankAccountsSnapshot empty = BankAccountsSnapshot();

  /// Accounts to render in the bottom strip — the primary is excluded because
  /// it already has its own card in the header.
  List<BankAccounts> get others => accounts
      .where((a) => a.userBankId.isEmpty || a.userBankId != primary?.userBankId)
      .toList();

  /// Total across every linked account (mixed currencies are summed as-is;
  /// the header formats with the primary account's currency).
  double get totalBalance =>
      accounts.fold<double>(0, (sum, a) => sum + a.balance);

  factory BankAccountsSnapshot.fromJson(Map<String, dynamic> json) {
    final accountsJson = (json['accounts'] as List?) ?? const [];
    final accounts = accountsJson
        .whereType<Map<String, dynamic>>()
        .map(BankAccounts.fromJson)
        .toList();

    // Backend always sends `primary`, but tolerate it being absent/empty.
    final primaryJson = json['primary'];
    final BankAccounts? primary = primaryJson is Map<String, dynamic>
        ? BankAccounts.fromJson(primaryJson)
        : null;

    return BankAccountsSnapshot(primary: primary, accounts: accounts);
  }
}

/// A bank in the read-only catalog — what the "link a bank" sheet lets the user
/// pick from (`GET /api/reference/banks`).
class BankCatalogEntry {
  final String bankId;
  final String code;
  final String bankName;
  final String gateway;
  final String currencyCode;
  final String countryCode;
  final String country;

  const BankCatalogEntry({
    required this.bankId,
    required this.code,
    required this.bankName,
    required this.gateway,
    required this.currencyCode,
    required this.countryCode,
    required this.country,
  });

  factory BankCatalogEntry.fromJson(Map<String, dynamic> json) =>
      BankCatalogEntry(
        bankId: (json['bankId'] ?? '').toString(),
        code: json['code'] ?? '',
        bankName: json['bankName'] ?? '',
        gateway: json['gateway'] ?? '',
        currencyCode: json['currencyCode'] ?? '',
        countryCode: json['countryCode'] ?? '',
        country: json['country'] ?? '',
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
  final String currencyCode;
  final String monthlyInstallment;
  final String? purpose;
  final String? decisionNote;

  Loan({
    required this.loanId,
    required this.principalAmount,
    required this.interestRate,
    required this.termMonths,
    required this.outstandingBalance,
    required this.status,
    this.dueDate,
    this.currencyCode = 'GHS',
    this.monthlyInstallment = '0',
    this.purpose,
    this.decisionNote,
  });

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
    loanId: json['loanId'] ?? '',
    principalAmount: (json['principalAmount'] ?? '0').toString(),
    interestRate: (json['interestRate'] ?? '0').toString(),
    termMonths: json['termMonths'] ?? 0,
    outstandingBalance: (json['outstandingBalance'] ?? '0').toString(),
    status: json['status'] ?? 'PENDING',
    dueDate: json['dueDate'],
    currencyCode: json['currencyCode'] ?? 'GHS',
    monthlyInstallment: (json['monthlyInstallment'] ?? '0').toString(),
    purpose: json['purpose'],
    decisionNote: json['decisionNote'],
  );
}

/// What the lender will offer this user (`GET /api/zbanking/loans/eligibility`):
/// KYC level, risk grade, limits, and — when they can't borrow — why not.
class LoanEligibility {
  final bool eligible;
  final int kycTier;
  final String? grade;
  final String currencyCode;
  final double minAmount;
  final double maxAmount;
  final int maxTermMonths;
  final double interestRate;
  final List<String> requirements;

  LoanEligibility({
    required this.eligible,
    required this.kycTier,
    this.grade,
    required this.currencyCode,
    required this.minAmount,
    required this.maxAmount,
    required this.maxTermMonths,
    required this.interestRate,
    required this.requirements,
  });

  factory LoanEligibility.fromJson(Map<String, dynamic> json) =>
      LoanEligibility(
        eligible: json['eligible'] ?? false,
        kycTier: (json['kycTier'] ?? 0) as int,
        grade: json['grade'],
        currencyCode: json['currencyCode'] ?? 'GHS',
        minAmount: double.tryParse('${json['minAmount'] ?? 0}') ?? 0,
        maxAmount: double.tryParse('${json['maxAmount'] ?? 0}') ?? 0,
        maxTermMonths: (json['maxTermMonths'] ?? 0) as int,
        interestRate: double.tryParse('${json['interestRate'] ?? 0}') ?? 0,
        requirements: ((json['requirements'] as List?) ?? const [])
            .map((e) => e.toString())
            .toList(),
      );
}

/// Everything the application form collects, as sent to `POST .../apply`.
class LoanApplication {
  final String amount;
  final String currencyCode;
  final int termMonths;
  final String purpose;
  final String employmentStatus;
  final String employerName;
  final String jobTitle;
  final String monthlyIncome;
  final String monthlyObligations;
  final String nextOfKinName;
  final String nextOfKinRelationship;
  final String nextOfKinPhone;
  final bool creditCheckConsent;
  final bool termsAccepted;

  LoanApplication({
    required this.amount,
    this.currencyCode = 'GHS',
    required this.termMonths,
    required this.purpose,
    required this.employmentStatus,
    this.employerName = '',
    this.jobTitle = '',
    required this.monthlyIncome,
    required this.monthlyObligations,
    required this.nextOfKinName,
    required this.nextOfKinRelationship,
    required this.nextOfKinPhone,
    required this.creditCheckConsent,
    required this.termsAccepted,
  });

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'currencyCode': currencyCode,
    'termMonths': termMonths,
    'purpose': purpose,
    'employmentStatus': employmentStatus,
    'employerName': employerName,
    'jobTitle': jobTitle,
    'monthlyIncome': monthlyIncome,
    'monthlyObligations': monthlyObligations,
    'nextOfKinName': nextOfKinName,
    'nextOfKinRelationship': nextOfKinRelationship,
    'nextOfKinPhone': nextOfKinPhone,
    'creditCheckConsent': creditCheckConsent,
    'termsAccepted': termsAccepted,
  };
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
