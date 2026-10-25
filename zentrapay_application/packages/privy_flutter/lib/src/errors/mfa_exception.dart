import 'package:privy_flutter/src/errors/privy_exception.dart';

/// Typed MFA error. All subtypes are also [PrivyException] so existing
/// catch-all `onFailure` handlers continue to work without changes.
sealed class MfaException extends PrivyException {
  const MfaException(super.message);
}

/// The submitted code was wrong, or a wallet operation requires MFA
/// verification before it can proceed.
///
/// Recovery: prompt the user to enter their code, call the appropriate
/// `verify.submit()`, then call `privy.mfa.resumeBlockedActions()`.
final class MfaMissingOrInvalidException extends MfaException {
  const MfaMissingOrInvalidException([
    super.message = 'MFA code missing or invalid',
  ]);
}

/// The server-side MFA challenge window elapsed before the user submitted
/// a code (distinct from the SDK-side listener timeout).
///
/// Recovery: restart the flow — call `sendCode()` / `generateSecret()` again.
final class MfaChallengeExpiredException extends MfaException {
  const MfaChallengeExpiredException([
    super.message = 'MFA challenge expired',
  ]);
}

/// The user submitted too many incorrect codes and the challenge is locked.
///
/// Recovery: start a new challenge — call `sendCode()` / `generateSecret()` again.
final class MfaMaxAttemptsReachedException extends MfaException {
  const MfaMaxAttemptsReachedException([
    super.message = 'MFA verification max attempts reached',
  ]);
}

/// `privy.mfa.resumeBlockedActions()` was not called within the configured
/// timeout after `onMfaRequired` fired.
///
/// Recovery: the blocked wallet operation is abandoned. Retry the wallet
/// operation from scratch — `onMfaRequired` will fire again.
final class MfaSdkTimeoutException extends MfaException {
  const MfaSdkTimeoutException([
    super.message = 'MFA verification timed out',
  ]);
}
