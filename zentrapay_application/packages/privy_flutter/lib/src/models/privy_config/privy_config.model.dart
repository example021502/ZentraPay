import 'package:privy_flutter/src/logging/privy_log_level_enum.dart';
import 'package:privy_flutter/src/models/login_with_custom_auth_config/login_with_custom_auth_config.dart';
import 'package:privy_flutter/src/modules/mfa/mfa_config.dart';
import 'package:privy_flutter/src/utils/json_serializable.dart';

class PrivyConfig implements JsonSerializable {
  /// The application ID.
  final String appId;

  /// The client ID for the application.
  final String appClientId;

  /// The logging level for the Privy SDK (defaults to `none` if null).
  final PrivyLogLevel logLevel;

  /// Optional configuration for custom authentication.
  final LoginWithCustomAuthConfig? customAuthConfig;

  /// Optional configuration for MFA behavior.
  final MfaConfig? mfaConfig;

  /// When true, wallets will not be automatically migrated to TEE after login.
  /// You must call `user.migrateWalletsIfNeeded()` manually.
  final bool disableAutomaticMigration;

  /// Constructs a [PrivyConfig] instance.
  /// Ensures `logLevel` is never null by defaulting to `PrivyLogLevel.none`.
  PrivyConfig({
    required this.appId,
    required this.appClientId,
    PrivyLogLevel? logLevel, // Accepts null but defaults below
    this.customAuthConfig,
    this.mfaConfig,
    this.disableAutomaticMigration = false,
  }) : logLevel = logLevel ?? PrivyLogLevel.none;

  /// Converts a JSON map to a [PrivyConfig] instance.
  @override
  Map<String, dynamic> toJson() {
    return {
      'appId': appId,
      'appClientId': appClientId,
      'logLevel': logLevel.toNativeString(),
      'shouldInitializeCustomAuth':
          customAuthConfig != null, // Flag for native to check
      'shouldInitializeMfa': mfaConfig != null, // Flag for native to check
      'mfaTimeoutMs': mfaConfig?.timeout.inMilliseconds,
      'disableAutomaticMigration': disableAutomaticMigration,
    };
  }
}
