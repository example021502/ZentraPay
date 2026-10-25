/// Represents an enrolled MFA method on a user.
///
/// Access via `user.mfaMethods`.
sealed class MfaMethod {
  const MfaMethod();

  factory MfaMethod.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final verifiedAt = json['verifiedAt'] as int;

    return switch (type) {
      'sms' => MfaMethodSms(verifiedAt: verifiedAt),
      'totp' => MfaMethodTotp(verifiedAt: verifiedAt),
      'passkey' => MfaMethodPasskey(verifiedAt: verifiedAt),
      _ => throw ArgumentError('Unknown MFA method type: $type'),
    };
  }
}

/// SMS-based MFA method.
class MfaMethodSms extends MfaMethod {
  /// Timestamp when this MFA method was last verified.
  final int verifiedAt;

  const MfaMethodSms({required this.verifiedAt});
}

/// Time-based One-Time Password (TOTP) MFA method.
class MfaMethodTotp extends MfaMethod {
  /// Timestamp when this MFA method was last verified.
  final int verifiedAt;

  const MfaMethodTotp({required this.verifiedAt});
}

/// Passkey-based MFA method.
class MfaMethodPasskey extends MfaMethod {
  /// Timestamp when this MFA method was last verified.
  final int verifiedAt;

  const MfaMethodPasskey({required this.verifiedAt});
}
