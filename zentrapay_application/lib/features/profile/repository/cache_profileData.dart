import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:zentrapay_application/core/models/user.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// Profile data caches: the `/api/users/me` user+profile snapshot and the
/// Tier-2 KYC document uploads. The profile repository implements the
/// "load once, then apply deltas" contract inline — there is no shared
/// abstract cache base anymore; it owns its own state and notifies
/// listeners. Home (notification tier badge), Payments (SendingForm) and
/// Settings also import this file.

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

  // ==========================================================================
  // Edit-profile writes — cache-then-async: the UI updates from the cached
  // value immediately (via updateUser/updateProfile above), the request
  // fires in the background, and a failure reverts to the pre-edit snapshot
  // (same pattern SecuritySettingsRepository already uses for its toggles).
  // ==========================================================================

  /// PATCH /api/users/me — name fields only. Null means "leave unchanged".
  Future<void> patchMe({String? firstName, String? lastName}) async {
    final previous = _data;
    if (firstName != null || lastName != null) {
      updateUser(
        (u) => u.copyWith(firstName: firstName, lastName: lastName),
      );
    }
    try {
      final response = await _dio.patch(
        '/api/users/me',
        data: {
          if (firstName != null) 'firstName': firstName,
          if (lastName != null) 'lastName': lastName,
        },
      );
      final updated = AppUser.fromJson(
        Map<String, dynamic>.from(response.data['data'] as Map),
      );
      applyDelta(
        (current) => UserProfileSnapshot(user: updated, profile: current.profile),
      );
    } catch (e) {
      if (previous != null) setData(previous);
      rethrow;
    }
  }

  /// PUT /api/users/me/profile — KYC fields. Every parameter optional (null
  /// = leave unchanged), so the edit form can submit one section at a time.
  Future<void> putProfile({
    DateTime? dateOfBirth,
    String? nationalityCountryCode,
    String? identityDocumentType,
    String? identityDocumentNumber,
    String? identityDocumentIssuingCountryCode,
    DateTime? identityDocumentExpirationDate,
    String? addressLine1,
    String? addressLine2,
    String? cityName,
    String? stateOrRegion,
    String? postalCode,
    String? occupationTitle,
  }) async {
    final previous = _data;
    // Comment: optimistic local merge — UserProfile's fields are mutable, so
    // patch the cached instance directly rather than rebuilding it. A no-op
    // when there's no cached profile yet (first-ever KYC submission); the
    // server response below populates it in that case.
    updateProfile((p) {
      if (dateOfBirth != null) p.dateOfBirth = dateOfBirth;
      if (nationalityCountryCode != null) {
        p.nationalityCountryCode = nationalityCountryCode;
      }
      if (identityDocumentType != null) {
        p.identityDocumentType = identityDocumentType;
      }
      if (identityDocumentNumber != null) {
        p.identityDocumentNumber = identityDocumentNumber;
      }
      if (identityDocumentIssuingCountryCode != null) {
        p.identityDocumentIssuingCountryCode =
            identityDocumentIssuingCountryCode;
      }
      if (identityDocumentExpirationDate != null) {
        p.identityDocumentExpirationDate = identityDocumentExpirationDate;
      }
      if (addressLine1 != null) p.addressLine1 = addressLine1;
      if (addressLine2 != null) p.addressLine2 = addressLine2;
      if (cityName != null) p.cityName = cityName;
      if (stateOrRegion != null) p.stateOrRegion = stateOrRegion;
      if (postalCode != null) p.postalCode = postalCode;
      if (occupationTitle != null) p.occupationTitle = occupationTitle;
      return p;
    });

    try {
      await _dio.put(
        '/api/users/me/profile',
        data: {
          if (dateOfBirth != null)
            'dateOfBirth': dateOfBirth.toIso8601String().split('T').first,
          if (nationalityCountryCode != null)
            'nationalityCountryCode': nationalityCountryCode,
          if (identityDocumentType != null)
            'identityDocumentType': identityDocumentType,
          if (identityDocumentNumber != null)
            'identityDocumentNumber': identityDocumentNumber,
          if (identityDocumentIssuingCountryCode != null)
            'identityDocumentIssuingCountryCode':
                identityDocumentIssuingCountryCode,
          if (identityDocumentExpirationDate != null)
            'identityDocumentExpirationDate': identityDocumentExpirationDate
                .toIso8601String()
                .split('T')
                .first,
          if (addressLine1 != null) 'addressLine1': addressLine1,
          if (addressLine2 != null) 'addressLine2': addressLine2,
          if (cityName != null) 'cityName': cityName,
          if (stateOrRegion != null) 'stateOrRegion': stateOrRegion,
          if (postalCode != null) 'postalCode': postalCode,
          if (occupationTitle != null) 'occupationTitle': occupationTitle,
        },
      );
      // Comment: the write also flips kycTier server-side on the user row —
      // refresh the whole snapshot (rather than just applying the PUT's own
      // response) so the tier badge updates in step with the profile fields.
      await refresh();
    } catch (e) {
      if (previous != null) setData(previous);
      rethrow;
    }
  }
}

/// Tier-2 KYC document uploads — POST/GET `/api/users/me/documents/{type}`.
/// `type` is one of `id-front|id-back|selfie`. Every successful upload
/// flips fields on the backend profile (and possibly `kycTier`), so callers
/// should refresh `UserProfileRepository` afterward rather than trying to
/// guess the new state locally.
class DocumentsRepository {
  static final Dio _dio = ApiClient().dio;

  static const List<String> validTypes = ['id-front', 'id-back', 'selfie'];

  static Future<void> upload({
    required String type,
    required String filePath,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    await _dio.post('/api/users/me/documents/$type', data: formData);
  }
}



