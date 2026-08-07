class SecuritySettings {
  final bool biometricEnabled;
  final String? biometricType;
  final bool twoFactorEnabled;
  final String? twoFactorMethod;
  final bool fraudProtectionEnabled;

  SecuritySettings({
    required this.biometricEnabled,
    this.biometricType,
    required this.twoFactorEnabled,
    this.twoFactorMethod,
    required this.fraudProtectionEnabled,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) =>
      SecuritySettings(
        biometricEnabled: json['biometricEnabled'] ?? false,
        biometricType: json['biometricType'],
        twoFactorEnabled: json['twoFactorEnabled'] ?? false,
        twoFactorMethod: json['twoFactorMethod'],
        fraudProtectionEnabled: json['fraudProtectionEnabled'] ?? true,
      );

  SecuritySettings copyWith({
    bool? biometricEnabled,
    bool? twoFactorEnabled,
    bool? fraudProtectionEnabled,
  }) => SecuritySettings(
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    biometricType: biometricType,
    twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    twoFactorMethod: twoFactorMethod,
    fraudProtectionEnabled:
        fraudProtectionEnabled ?? this.fraudProtectionEnabled,
  );
}

class FraudAlert {
  final String alertId;
  final String alertType;
  final String message;
  final String severity;
  final bool isResolved;
  final String createdAt;

  FraudAlert({
    required this.alertId,
    required this.alertType,
    required this.message,
    required this.severity,
    required this.isResolved,
    required this.createdAt,
  });

  factory FraudAlert.fromJson(Map<String, dynamic> json) => FraudAlert(
    alertId: json['alertId'] ?? '',
    alertType: json['alertType'] ?? '',
    message: json['message'] ?? '',
    severity: json['severity'] ?? 'LOW',
    isResolved: json['isResolved'] ?? false,
    createdAt: json['createdAt'] ?? '',
  );
}

class LoginHistoryEntry {
  final String loginId;
  final String? ipAddress;
  final String? deviceInfo;
  final String? location;
  final bool success;
  final String createdAt;

  LoginHistoryEntry({
    required this.loginId,
    this.ipAddress,
    this.deviceInfo,
    this.location,
    required this.success,
    required this.createdAt,
  });

  factory LoginHistoryEntry.fromJson(Map<String, dynamic> json) =>
      LoginHistoryEntry(
        loginId: json['loginId'] ?? '',
        ipAddress: json['ipAddress'],
        deviceInfo: json['deviceInfo'],
        location: json['location'],
        success: json['success'] ?? true,
        createdAt: json['createdAt'] ?? '',
      );
}
