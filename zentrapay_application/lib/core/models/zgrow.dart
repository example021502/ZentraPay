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

class Reward {
  final String rewardId;
  final String rewardType;
  final String title;
  final String description;
  final double worth;
  final String currencyCode;
  final bool isActive;
  final DateTime createdOn;
  final DateTime updatedOn;

  Reward({
    required this.rewardId,
    required this.rewardType,
    required this.title,
    required this.description,
    required this.worth,
    required this.currencyCode,
    required this.isActive,
    required this.createdOn,
    required this.updatedOn,
  });

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
    rewardId: json['rewardId'],
    rewardType: json['rewardType'],
    title: json['title'],
    description: json['description'],
    worth: json['worth'],
    currencyCode: json['rewardType'],
    isActive: json['isActive'],
    createdOn: json['createdOn'],
    updatedOn: json['updatedOn'],
  );
}

// Container class holding a list of Reward models
class RewardsList {
  final List<Reward> rewards;

  RewardsList({required this.rewards});

  // Factory constructor to map a JSON list to a RewardsList instance
  factory RewardsList.fromJson(List<dynamic>? json) {
    if (json == null) {
      return RewardsList(rewards: []);
    }

    return RewardsList(
      rewards: json
          .map((item) => Reward.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
