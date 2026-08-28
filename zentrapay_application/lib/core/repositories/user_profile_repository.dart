// UserProfileRepository implementation in Dart
import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/models/user.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// Cache manager for user profile data fetched from `/api/users/me`.
///
/// Follows the app-wide "load once, then apply deltas" contract
/// (see [CachedResource]): screens call `UserProfileRepository.instance
/// .ensureLoaded()` in `initState`, the first caller triggers the GET and
/// every subsequent caller gets the already-cached snapshot instantly.
class UserProfileRepository extends CachedResource<UserProfileSnapshot> {
  UserProfileRepository._();
  static final UserProfileRepository instance = UserProfileRepository._();

  final Dio _dio = ApiClient().dio;

  /// Returns the cached account record, or null until the first
  /// successful load.
  AppUser? get userInfo => data?.user;

  /// Returns the cached KYC profile record, or null while it has not
  /// been loaded yet or the user has not submitted their KYC details.
  UserProfile? get userProfile => data?.profile;

  /// True once the account record is available in cache.
  @override
  bool get isLoaded => data != null;

  @override
  Future<UserProfileSnapshot> fetch() async {
    final response = await _dio.get('/api/users/me');

    // Parse JSON response into UserProfileSnapshot model
    return UserProfileSnapshot.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
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
}
