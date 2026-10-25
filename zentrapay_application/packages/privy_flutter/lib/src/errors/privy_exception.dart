import 'package:flutter/services.dart';
import 'package:privy_flutter/src/errors/mfa_exception.dart';

/// A class representing all Privy SDK exceptions.
class PrivyException implements Exception {
  /// The error message describing the exception.
  final String message;

  /// Constructor for [PrivyException].
  const PrivyException(this.message);

  @override
  String toString() => "PrivyException: $message";
}

/// Extension to convert `Exception` into `PrivyException`
extension ExceptionConversion on Object {
  PrivyException convertToPrivyException(
      [String defaultErrorMessage = "Unexpected error"]) {
    if (this is PlatformException) {
      final e = this as PlatformException;
      final message = e.message ?? defaultErrorMessage;
      return switch (e.code) {
        'MFA_MISSING_OR_INVALID' => MfaMissingOrInvalidException(message),
        'MFA_CHALLENGE_EXPIRED' => MfaChallengeExpiredException(message),
        'MFA_MAX_ATTEMPTS_REACHED' => MfaMaxAttemptsReachedException(message),
        'MFA_SDK_TIMEOUT' => MfaSdkTimeoutException(message),
        _ => PrivyException(message),
      };
    } else {
      return PrivyException("$defaultErrorMessage: $this");
    }
  }
}
