import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/zgrow.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';

class ChallengesRepository extends CachedListResource<Challenge> {
  ChallengesRepository._();
  static final ChallengesRepository instance = ChallengesRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<Challenge>> fetch() async {
    final response = await _dio.get('/api/zgrow/challenges');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => Challenge.fromJson(e))
        .toList();
  }

  Future<void> join(String challengeId) async {
    final response = await _dio.post(
      '/api/zgrow/challenges/$challengeId/join',
    );
    final updated = Challenge.fromJson(response.data['data']);
    replaceItem((c) => c.challengeId == challengeId, updated);
  }

  Future<void> decline(String challengeId) async {
    final response = await _dio.post(
      '/api/zgrow/challenges/$challengeId/decline',
    );
    final updated = Challenge.fromJson(response.data['data']);
    replaceItem((c) => c.challengeId == challengeId, updated);
  }
}

class LiteracyRepository extends CachedListResource<LiteracyContent> {
  LiteracyRepository._();
  static final LiteracyRepository instance = LiteracyRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<LiteracyContent>> fetch() async {
    final response = await _dio.get('/api/zgrow/literacy');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => LiteracyContent.fromJson(e))
        .toList();
  }

  Future<int> complete(String contentId) async {
    final response = await _dio.post(
      '/api/zgrow/literacy/$contentId/complete',
    );
    final pointsEarned = response.data['data']?['pointsEarned'] ?? 0;
    replaceItem(
      (c) => c.contentId == contentId,
      data!.firstWhere((c) => c.contentId == contentId).copyWith(completed: true),
    );
    RewardsRepository.instance.ensureLoaded(forceRefresh: true);
    return pointsEarned;
  }
}

class RewardsRepository extends CachedResource<RewardsSummary> {
  RewardsRepository._();
  static final RewardsRepository instance = RewardsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<RewardsSummary> fetch() async {
    final response = await _dio.get('/api/zgrow/rewards');
    return RewardsSummary.fromJson(response.data['data']);
  }
}
