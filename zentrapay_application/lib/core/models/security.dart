/// The user's settings row (`GET /api/secure/status`): security toggles plus
/// app preferences. Immutable — an optimistic change is a [copyWith] copy.
class SecuritySettings {
  final bool biometricEnabled;
  final String? biometricType;
  final bool twoFactorEnabled;
  final String? twoFactorMethod;
  final bool fraudProtectionEnabled;
  final bool darkMode;
  final bool pushNotificationsEnabled;
  final bool transactionAlertsEnabled;

  SecuritySettings({
    required this.biometricEnabled,
    this.biometricType,
    required this.twoFactorEnabled,
    this.twoFactorMethod,
    required this.fraudProtectionEnabled,
    this.darkMode = false,
    this.pushNotificationsEnabled = true,
    this.transactionAlertsEnabled = true,
  });

  factory SecuritySettings.fromJson(Map<String, dynamic> json) =>
      SecuritySettings(
        biometricEnabled: json['biometricEnabled'] ?? false,
        biometricType: json['biometricType'],
        twoFactorEnabled: json['twoFactorEnabled'] ?? false,
        twoFactorMethod: json['twoFactorMethod'],
        fraudProtectionEnabled: json['fraudProtectionEnabled'] ?? true,
        darkMode: json['darkMode'] ?? false,
        pushNotificationsEnabled: json['pushNotificationsEnabled'] ?? true,
        transactionAlertsEnabled: json['transactionAlertsEnabled'] ?? true,
      );

  SecuritySettings copyWith({
    bool? biometricEnabled,
    bool? twoFactorEnabled,
    bool? fraudProtectionEnabled,
    bool? darkMode,
    bool? pushNotificationsEnabled,
    bool? transactionAlertsEnabled,
  }) => SecuritySettings(
    biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    biometricType: biometricType,
    twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    twoFactorMethod: twoFactorMethod,
    fraudProtectionEnabled:
        fraudProtectionEnabled ?? this.fraudProtectionEnabled,
    darkMode: darkMode ?? this.darkMode,
    pushNotificationsEnabled:
        pushNotificationsEnabled ?? this.pushNotificationsEnabled,
    transactionAlertsEnabled:
        transactionAlertsEnabled ?? this.transactionAlertsEnabled,
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
