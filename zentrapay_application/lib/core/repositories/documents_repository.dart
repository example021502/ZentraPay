import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

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
