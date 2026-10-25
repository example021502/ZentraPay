import 'package:dio/dio.dart';
import 'package:zentrapay_application/core/utils/interceptor.dart';

/// Which secret is being changed or recovered.
enum CredentialKind { password, pin }

/// Change / forgot / reset for the account password and the transaction PIN
/// (`/api/users/{password|pin}/...`). Each call is a deliberate user action,
/// so nothing here is cached.
class CredentialService {
  static final Dio _dio = ApiClient().dio;

  static String _base(CredentialKind kind) =>
      kind == CredentialKind.pin ? '/api/users/pin' : '/api/users/password';

  /// Sets a new value; the current one must be supplied.
  static Future<void> change(
    CredentialKind kind, {
    required String current,
    required String next,
  }) async {
    await _dio.post(
      '${_base(kind)}/change',
      data: kind == CredentialKind.pin
          ? {'currentPin': current, 'newPin': next}
          : {'currentPassword': current, 'newPassword': next},
    );
  }

  /// Emails a one-time code to the registered address. Returns a masked hint
  /// of that address (e.g. `j***@mail.com`).
  static Future<String> requestReset(CredentialKind kind) async {
    final response = await _dio.post('${_base(kind)}/forgot');
    final data = response.data['data'];
    return data is Map ? (data['emailHint']?.toString() ?? '') : '';
  }

  /// Checks the pasted code. Returns the short-lived reset token that opens
  /// the "new value" step.
  static Future<String> verifyCode(CredentialKind kind, String code) async {
    final response = await _dio.post(
      '${_base(kind)}/verify-code',
      data: {'code': code.trim()},
    );
    final data = response.data['data'];
    final token = data is Map ? data['resetToken']?.toString() : null;
    if (token == null || token.isEmpty) {
      throw StateError('Reset token missing');
    }
    return token;
  }

  /// Sets the new value using the token from [verifyCode].
  static Future<void> reset(
    CredentialKind kind, {
    required String resetToken,
    required String next,
  }) async {
    await _dio.post(
      '${_base(kind)}/reset',
      data: kind == CredentialKind.pin
          ? {'resetToken': resetToken, 'newPin': next}
          : {'resetToken': resetToken, 'newPassword': next},
    );
  }
}
