import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';
import 'package:zentrapay_application/core/models/user.dart';
import 'package:zentrapay_application/core/repositories/cached_resource.dart';

class ProfileRepository extends CachedResource<AppUser> {
  ProfileRepository._();
  static final ProfileRepository instance = ProfileRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<AppUser> fetch() async {
    final response = await _dio.get('/api/users/me');
    return AppUser.fromJson(response.data['data']);
  }

  Future<AppUser> updateBasicInfo({String? firstName, String? lastName}) async {
    final response = await _dio.patch(
      '/api/users/me',
      data: {
        'firstName': ?firstName,
        'lastName': ?lastName,
      },
    );
    final user = AppUser.fromJson(response.data['data']);
    setData(user);
    return user;
  }
}

class UserProfileDetailsRepository extends CachedResource<UserProfileDetails> {
  UserProfileDetailsRepository._();
  static final UserProfileDetailsRepository instance =
      UserProfileDetailsRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<UserProfileDetails> fetch() async {
    final response = await _dio.get('/api/users/me/profile');
    return UserProfileDetails.fromJson(response.data['data'] ?? {});
  }

  Future<UserProfileDetails> save(UserProfileDetails details) async {
    final response = await _dio.put(
      '/api/users/me/profile',
      data: details.toJson(),
    );
    final updated = UserProfileDetails.fromJson(response.data['data']);
    setData(updated);
    return updated;
  }
}

class MerchantProfileRepository
    extends CachedResource<MerchantProfileDetails?> {
  MerchantProfileRepository._();
  static final MerchantProfileRepository instance =
      MerchantProfileRepository._();

  final Dio _dio = ApiClient().dio;

  @override
  Future<MerchantProfileDetails?> fetch() async {
    final response = await _dio.get('/api/users/me/merchant-profile');
    final data = response.data['data'];
    return data == null ? null : MerchantProfileDetails.fromJson(data);
  }

  Future<MerchantProfileDetails> save(MerchantProfileDetails details) async {
    final response = await _dio.put(
      '/api/users/me/merchant-profile',
      data: details.toJson(),
    );
    final updated = MerchantProfileDetails.fromJson(response.data['data']);
    setData(updated);
    return updated;
  }
}
