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
  final int rewardId;
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
    rewardId: _parseInt(json['rewardId']),
    rewardType: json['rewardType']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    worth: _parseWorth(json['worth']),
    currencyCode:
        (json['currencyCode'] ?? json['rewardType'])?.toString() ?? '',
    isActive:
        json['isActive'] == true ||
        json['isActive'] == 'true' ||
        json['isActive'] == 1,
    createdOn: DateTime.tryParse('${json['createdOn']}') ?? DateTime.now(),
    updatedOn: DateTime.tryParse('${json['updatedOn']}') ?? DateTime.now(),
  );

  static int _parseInt(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse('$raw') ?? 0;
  }

  static double _parseWorth(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse('$raw') ?? 0.0;
  }

  @override
  String toString() =>
      'Reward($currencyCode $worth — $title, '
      'type: $rewardType, active: $isActive)';
}

class RewardsList {
  final List<Reward> rewards;

  RewardsList({required this.rewards});

  factory RewardsList.fromJson(dynamic json) {
    final List<dynamic> raw;
    if (json is List) {
      raw = json;
    } else if (json is Map) {
      raw = (json['rewards'] as List?) ?? const [];
    } else {
      raw = const [];
    }

    return RewardsList(
      rewards: raw
          .whereType<Map>()
          .map((item) => Reward.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  @override
  String toString() =>
      'RewardsList(${rewards.length} rewards: '
      '${rewards.map((r) => r.title).join(", ")})';
}

class Tutorial {
  final int id;
  final String title;
  final String type;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int durationSeconds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tutorial({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.durationSeconds,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tutorial.fromJson(Map<String, dynamic> json) => Tutorial(
    id: _parseInt(json['id']),
    title: json['title'] ?? 'Unknown',
    type: json['type'] ?? 'Unknown',
    description: json['description'] ?? 'Unknown',
    videoUrl: json['videoUrl'] ?? 'Unknown',
    thumbnailUrl: json['thumbnailUrl'] ?? 'Unknown',
    durationSeconds: _parseInt(json['durationSeconds']),
    isActive: json['isActive'] == true,
    createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
    updatedAt: DateTime.tryParse('${json['updatedAt']}') ?? DateTime.now(),
  );

  static int _parseInt(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse('$raw') ?? 0;
  }

  @override
  String toString() =>
      'Tutorial(#$id: $title, duration: ${durationSeconds}s, '
      'active: $isActive)';
}

class TutorialsList {
  final List<Tutorial> tutorials;

  TutorialsList({required this.tutorials});

  factory TutorialsList.fromJson(List<dynamic> json) {
    return TutorialsList(
      tutorials: json
          .map((item) => Tutorial.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }

  @override
  String toString() =>
      'TutorialsList(${tutorials.length} tutorials: '
      '${tutorials.map((t) => t.title).join(", ")})';
}
