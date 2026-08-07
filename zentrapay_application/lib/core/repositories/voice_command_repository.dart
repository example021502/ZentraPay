import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/voice_command.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';

class VoiceCommandHistoryRepository extends CachedListResource<VoiceCommandResult> {
  VoiceCommandHistoryRepository._();
  static final VoiceCommandHistoryRepository instance =
      VoiceCommandHistoryRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<VoiceCommandResult>> fetch() async {
    final response = await _dio.get('/api/zvoice/history');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => VoiceCommandResult.fromJson(e))
        .toList();
  }

  Future<VoiceCommandResult> sendCommand({
    required String commandType,
    required String transcript,
    String language = 'en',
    bool fraudAlert = false,
    String? fraudReason,
  }) async {
    final response = await _dio.post(
      '/api/zvoice/command',
      data: {
        'commandType': commandType,
        'language': language,
        'transcript': transcript,
        'fraudAlert': fraudAlert,
        'fraudReason': ?fraudReason,
      },
    );
    final result = VoiceCommandResult.fromJson(response.data['data']);
    addItem(result);
    return result;
  }
}

class VoiceFraudAlertsRepository extends CachedListResource<VoiceCommandResult> {
  VoiceFraudAlertsRepository._();
  static final VoiceFraudAlertsRepository instance =
      VoiceFraudAlertsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<VoiceCommandResult>> fetch() async {
    final response = await _dio.get('/api/zvoice/fraud-alerts');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => VoiceCommandResult.fromJson(e))
        .toList();
  }
}
