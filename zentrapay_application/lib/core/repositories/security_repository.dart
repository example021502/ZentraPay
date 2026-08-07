import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/security.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';

class SecuritySettingsRepository extends CachedResource<SecuritySettings> {
  SecuritySettingsRepository._();
  static final SecuritySettingsRepository instance =
      SecuritySettingsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<SecuritySettings> fetch() async {
    final response = await _dio.get('/api/secure/status');
    return SecuritySettings.fromJson(response.data['data']);
  }

  Future<void> setBiometric(bool enabled, {String type = 'FINGERPRINT'}) async {
    final response = await _dio.post(
      '/api/secure/biometric',
      data: {'enabled': enabled, 'type': type},
    );
    setData(SecuritySettings.fromJson(response.data['data']));
  }

  Future<void> setTwoFactor(bool enabled, {String? method}) async {
    final response = await _dio.post(
      '/api/secure/2fa',
      data: {'enabled': enabled, 'method': ?method},
    );
    setData(SecuritySettings.fromJson(response.data['data']));
  }

  Future<void> setFraudProtection(bool enabled) async {
    final response = await _dio.post(
      '/api/secure/fraud-protection',
      data: {'enabled': enabled},
    );
    setData(SecuritySettings.fromJson(response.data['data']));
  }
}

class FraudAlertsRepository extends CachedListResource<FraudAlert> {
  FraudAlertsRepository._();
  static final FraudAlertsRepository instance = FraudAlertsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<FraudAlert>> fetch() async {
    final response = await _dio.get('/api/secure/fraud-alerts');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => FraudAlert.fromJson(e))
        .toList();
  }
}

class LoginHistoryRepository extends CachedListResource<LoginHistoryEntry> {
  LoginHistoryRepository._();
  static final LoginHistoryRepository instance = LoginHistoryRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<List<LoginHistoryEntry>> fetch() async {
    final response = await _dio.get('/api/secure/login-history');
    return ((response.data['data'] as List?) ?? [])
        .map((e) => LoginHistoryEntry.fromJson(e))
        .toList();
  }
}
