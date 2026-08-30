import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/models/user.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// Data snapshot holding both user and profile instances.
class UserProfileSnapshot {
  final AppUser user;
  final UserProfile? profile;

  UserProfileSnapshot({required this.user, this.profile});

  factory UserProfileSnapshot.fromJson(Map<String, dynamic> json) {
    return UserProfileSnapshot(
      user: AppUser.fromJson(
        (json['user'] as Map<String, dynamic>?) ?? const {},
      ),
      profile: json['profile'] != null
          ? UserProfile.fromJson(
              Map<String, dynamic>.from(json['profile'] as Map),
            )
          : null,
    );
  }
}

/// Standalone Repository manager for user profile data fetched from `/api/users/me`.
class UserProfileRepository with ChangeNotifier {
  UserProfileRepository._();
  static final UserProfileRepository instance = UserProfileRepository._();

  final Dio _dio = ApiClient().dio;

  // Local state fields
  UserProfileSnapshot? _data;
  Object? _error;
  bool _isLoading = false;

  /// Getters for current cached state
  UserProfileSnapshot? get data => _data;
  Object? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoaded => _data != null;

  /// Quick getters for models
  AppUser? get user => _data?.user;
  UserProfile? get profile => _data?.profile;

  /// Fetches profile data from server if not already cached.
  Future<UserProfileSnapshot?> ensureLoaded() async {
    if (isLoaded) return _data;
    return refresh();
  }

  /// Forces a GET call to retrieve fresh profile data from `/api/users/me`.
  Future<UserProfileSnapshot?> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dio.get('/api/users/me');
      // The backend wraps every payload in an ApiResponse envelope of the form
      // {success, data, message}. The user/profile snapshot lives under `data`.
      final rawBody = Map<String, dynamic>.from(response.data as Map);
      final payload = rawBody['data'] is Map
          ? Map<String, dynamic>.from(rawBody['data'] as Map)
          : rawBody;
      _data = UserProfileSnapshot.fromJson(payload);
      print("THE DATA RESPONSE IS:: $response");
      return _data;
    } catch (e) {
      _error = e;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates only the AppUser instance in cache.
  void updateUser(AppUser Function(AppUser current) updater) {
    applyDelta(
      (current) => UserProfileSnapshot(
        user: updater(current.user),
        profile: current.profile,
      ),
    );
  }

  /// Updates only the UserProfile instance in cache.
  void updateProfile(UserProfile Function(UserProfile current) updater) {
    applyDelta((current) {
      final profile = current.profile;
      if (profile == null) return current;
      return UserProfileSnapshot(user: current.user, profile: updater(profile));
    });
  }

  /// Applies a POST/PUT response onto the cached value without refetching.
  void applyDelta(
    UserProfileSnapshot Function(UserProfileSnapshot current) updater,
  ) {
    final current = _data;
    if (current == null) return;
    _data = updater(current);
    notifyListeners();
  }

  /// Replaces the cached value outright.
  void setData(UserProfileSnapshot value) {
    _data = value;
    _error = null;
    notifyListeners();
  }

  /// Clears local state and resets errors.
  void clear() {
    _data = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
