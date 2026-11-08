// Models of the Save Goal section - mirror `SavingsGoalDTOs` of the backend
// (`/api/zbanking/savings/*`).

/// How often an automatic save runs. The wire value is the enum name in capitals.
enum AutoSaveFrequency {
  daily('DAILY', 'Every day', 'daily'),
  weekly('WEEKLY', 'Every week', 'weekly'),
  monthly('MONTHLY', 'Every month', 'monthly');

  final String wire;
  final String label;
  final String adverb;

  const AutoSaveFrequency(this.wire, this.label, this.adverb);

  static AutoSaveFrequency? fromWire(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    for (final f in values) {
      if (f.wire == v) return f;
    }
    return null;
  }
}

DateTime? _parseInstant(Object? value) {
  if (value == null) return null;
  // The server sends an ISO instant (UTC); shown in the phone's own time zone
  return DateTime.tryParse(value.toString())?.toLocal();
}

/// One savings goal with its progress, freeze and auto-save state.
class SavingsGoal {
  /// The longest a goal can be frozen (the backend refuses more).
  static const int maxFreezeDays = 7;

  final String savingsId;
  final String savingsName;
  final String currencyCode;
  final double balance;
  final double? targetAmount;
  final DateTime? targetDate;
  final String status;
  final String? description;

  /// Saving is blocked until this moment. Null when the goal is not frozen.
  final DateTime? frozenUntil;
  final bool autoSaveEnabled;
  final double? autoSaveAmount;
  final AutoSaveFrequency? autoSaveFrequency;
  final DateTime? autoSaveNextRun;
  final DateTime? createdAt;

  const SavingsGoal({
    required this.savingsId,
    required this.savingsName,
    required this.currencyCode,
    required this.balance,
    this.targetAmount,
    this.targetDate,
    required this.status,
    this.description,
    this.frozenUntil,
    this.autoSaveEnabled = false,
    this.autoSaveAmount,
    this.autoSaveFrequency,
    this.autoSaveNextRun,
    this.createdAt,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) => SavingsGoal(
    savingsId: (json['savingsId'] ?? '').toString(),
    savingsName: (json['savingsName'] ?? '').toString(),
    currencyCode: (json['currencyCode'] ?? '').toString(),
    balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    targetAmount: (json['targetAmount'] as num?)?.toDouble(),
    targetDate: json['targetDate'] != null
        ? DateTime.tryParse(json['targetDate'].toString())
        : null,
    status: (json['status'] ?? '').toString(),
    description: json['description']?.toString(),
    frozenUntil: _parseInstant(json['frozenUntil']),
    autoSaveEnabled: json['autoSaveEnabled'] == true,
    autoSaveAmount: (json['autoSaveAmount'] as num?)?.toDouble(),
    autoSaveFrequency: AutoSaveFrequency.fromWire(
      json['autoSaveFrequency']?.toString(),
    ),
    autoSaveNextRun: _parseInstant(json['autoSaveNextRun']),
    createdAt: _parseInstant(json['createdAt']),
  );

  /// True while saving into the goal is blocked. Checked against the clock, so a freeze
  /// that has run out stops showing even before the list is reloaded.
  bool get isFrozen {
    final until = frozenUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  bool get hasTarget => (targetAmount ?? 0) > 0;

  bool get isReached =>
      status.toUpperCase() == 'COMPLETED' ||
      (hasTarget && balance >= (targetAmount ?? 0));

  /// 0..1 progress towards the target (0 when the goal has no target).
  double get progress =>
      hasTarget ? (balance / targetAmount!).clamp(0.0, 1.0) : 0.0;
}

/// One line of "recent saving activity" (`GET /api/zbanking/savings/activity`).
class GoalActivity {
  final String activityId;
  final String? savingsId;
  final String savingsName;

  /// DEPOSIT or WITHDRAWAL
  final String type;

  /// An automatic (scheduled) save rather than a tap by the user.
  final bool auto;
  final double amount;
  final String currencyCode;

  /// SUCCESS, FAILED ...
  final String status;
  final String? failureReason;
  final DateTime? createdAt;

  const GoalActivity({
    required this.activityId,
    required this.savingsId,
    required this.savingsName,
    required this.type,
    required this.auto,
    required this.amount,
    required this.currencyCode,
    required this.status,
    this.failureReason,
    this.createdAt,
  });

  factory GoalActivity.fromJson(Map<String, dynamic> json) => GoalActivity(
    activityId: (json['activityId'] ?? '').toString(),
    savingsId: json['savingsId']?.toString(),
    savingsName: (json['savingsName'] ?? 'Savings goal').toString(),
    type: (json['type'] ?? '').toString().toUpperCase(),
    auto: json['auto'] == true,
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    currencyCode: (json['currencyCode'] ?? '').toString(),
    status: (json['status'] ?? '').toString().toUpperCase(),
    failureReason: json['failureReason']?.toString(),
    createdAt: _parseInstant(json['createdAt']),
  );

  bool get isDeposit => type == 'DEPOSIT';
  bool get failed => status == 'FAILED' || status == 'EXPIRED';
}
