class Challenge {
  final String challengeId;
  final String title;
  final String description;
  final String category;
  final int durationDays;
  final int pointsReward;
  final String difficulty;
  final int participantsCount;
  final bool joined;
  final int progressPercent;

  Challenge({
    required this.challengeId,
    required this.title,
    required this.description,
    required this.category,
    required this.durationDays,
    required this.pointsReward,
    required this.difficulty,
    required this.participantsCount,
    required this.joined,
    required this.progressPercent,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
    challengeId: json['challengeId'] ?? '',
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? '',
    durationDays: json['durationDays'] ?? 0,
    pointsReward: json['pointsReward'] ?? 0,
    difficulty: json['difficulty'] ?? 'EASY',
    participantsCount: json['participantsCount'] ?? 0,
    joined: json['joined'] ?? false,
    progressPercent: json['progressPercent'] ?? 0,
  );

  Challenge copyWith({bool? joined, int? participantsCount}) => Challenge(
    challengeId: challengeId,
    title: title,
    description: description,
    category: category,
    durationDays: durationDays,
    pointsReward: pointsReward,
    difficulty: difficulty,
    participantsCount: participantsCount ?? this.participantsCount,
    joined: joined ?? this.joined,
    progressPercent: progressPercent,
  );
}

class LiteracyContent {
  final String contentId;
  final String title;
  final String category;
  final String? contentUrl;
  final int durationMinutes;
  final int pointsReward;
  final bool completed;

  LiteracyContent({
    required this.contentId,
    required this.title,
    required this.category,
    this.contentUrl,
    required this.durationMinutes,
    required this.pointsReward,
    required this.completed,
  });

  factory LiteracyContent.fromJson(Map<String, dynamic> json) =>
      LiteracyContent(
        contentId: json['contentId'] ?? '',
        title: json['title'] ?? '',
        category: json['category'] ?? '',
        contentUrl: json['contentUrl'],
        durationMinutes: json['durationMinutes'] ?? 0,
        pointsReward: json['pointsReward'] ?? 0,
        completed: json['completed'] ?? false,
      );

  LiteracyContent copyWith({bool? completed}) => LiteracyContent(
    contentId: contentId,
    title: title,
    category: category,
    contentUrl: contentUrl,
    durationMinutes: durationMinutes,
    pointsReward: pointsReward,
    completed: completed ?? this.completed,
  );
}

class PointsLedgerEntry {
  final int points;
  final String reason;
  final String createdAt;

  PointsLedgerEntry({
    required this.points,
    required this.reason,
    required this.createdAt,
  });

  factory PointsLedgerEntry.fromJson(Map<String, dynamic> json) =>
      PointsLedgerEntry(
        points: json['points'] ?? 0,
        reason: json['reason'] ?? '',
        createdAt: json['createdAt'] ?? '',
      );
}

class RewardsSummary {
  final int totalPoints;
  final String tier;
  final List<PointsLedgerEntry> recentLedger;

  RewardsSummary({
    required this.totalPoints,
    required this.tier,
    required this.recentLedger,
  });

  factory RewardsSummary.fromJson(Map<String, dynamic> json) => RewardsSummary(
    totalPoints: json['totalPoints'] ?? 0,
    tier: json['tier'] ?? 'BRONZE',
    recentLedger: ((json['recentLedger'] as List?) ?? [])
        .map((e) => PointsLedgerEntry.fromJson(e))
        .toList(),
  );
}
