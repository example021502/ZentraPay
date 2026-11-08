import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/user_service.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// The services THIS USER added to their Home screen with the "New" button (`/api/user-services`).
///
/// Home shows only these - not the whole provider directory, which stays in its own repositories
/// ([BillProvidersRepository] / [ServiceProvidersRepository]) and feeds the picker the user adds from.
class UserServicesRepository extends ChangeNotifier {
  UserServicesRepository._();
  static final UserServicesRepository instance = UserServicesRepository._();

  final Dio _dio = ApiClient().dio;

  List<UserService>? _data;
  bool _loading = false;
  Object? _error;

  List<UserService>? get data => _data;
  bool get isLoaded => _data != null;
  bool get isLoading => _loading;
  Object? get error => _error;

  List<UserService> get bills => [...?_data?.where((s) => s.isBill)];
  List<UserService> get services => [...?_data?.where((s) => !s.isBill)];

  bool has(String kind, String providerId) =>
      _data?.any((s) => s.kind == kind && s.providerId == providerId) ?? false;

  Future<List<UserService>?> ensureLoaded({bool forceRefresh = false}) async {
    if (_data != null && !forceRefresh) return _data;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _dio.get('/api/user-services');
      final raw = response.data['data'];
      _data = [
        if (raw is List)
          for (final e in raw)
            if (e is Map) UserService.fromJson(Map<String, dynamic>.from(e)),
      ];
      return _data;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Adds a provider to Home. [kind] is [UserService.bill] or [UserService.service].
  Future<UserService> add(String kind, String providerId) async {
    final response = await _dio.post(
      '/api/user-services',
      data: {'kind': kind, 'providerId': providerId},
    );
    final added = UserService.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
    _data = [
      ...?_data?.where((s) => !(s.kind == added.kind && s.providerId == added.providerId)),
      added,
    ];
    notifyListeners();
    return added;
  }

  Future<void> remove(String kind, String providerId) async {
    await _dio.delete('/api/user-services/$kind/$providerId');
    _data = [...?_data?.where((s) => !(s.kind == kind && s.providerId == providerId))];
    notifyListeners();
  }

  void clear() {
    _data = null;
    _error = null;
    _loading = false;
    notifyListeners();
  }
}
