import 'package:flutter/services.dart';
import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/mfa/mfa_config.dart';
import 'package:privy_flutter/src/modules/mfa/privy_mfa.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

class RealPrivyMfa implements PrivyMfa {
  final MethodChannelHandler _channelHandler;
  MfaConfig? _config;

  RealPrivyMfa(
    this._channelHandler, {
    MfaConfig? initialConfig,
  }) : _config = initialConfig;

  /// Handles the onMfaRequired callback from native.
  /// Called by PrivyImpl's method call handler routing.
  void handleOnMfaRequired(MethodCall call) {
    final config = _config;
    if (config == null) {
      LoggerService.debug(
          "onMfaRequired received from native but no MfaConfig set.");
      return;
    }

    final args = call.arguments as Map<Object?, Object?>?;
    if (args == null) {
      LoggerService.error("onMfaRequired called with null arguments.");
      return;
    }

    final userData = safeCastToMap(args);
    final user = RealPrivyUser.fromJson(userData);
    LoggerService.debug("onMfaRequired fired for user: ${user.id}");
    config.listener.onMfaRequired(user);
  }

  @override
  Future<Result<void>> setConfig(MfaConfig config) async {
    _config = config;
    LoggerService.debug("Setting MFA config on native.");

    try {
      await _channelHandler.invokeMethod<void>(
        'mfaSetConfig',
        {'timeoutMs': config.timeout.inMilliseconds},
      );
      return const Success(null);
    } catch (e) {
      LoggerService.error("Failed to set MFA config: $e");
      return Failure(e.convertToPrivyException("Failed to set MFA config"));
    }
  }

  @override
  Future<Result<void>> resumeBlockedActions([Exception? mfaError]) async {
    LoggerService.debug(
        "Calling resumeBlockedActions on native. Error: $mfaError");

    try {
      await _channelHandler.invokeMethod<void>(
        'mfaResumeBlockedActions',
        {'error': mfaError?.toString()},
      );
      return const Success(null);
    } catch (e) {
      LoggerService.error("Failed to resume blocked actions: $e");
      return Failure(
          e.convertToPrivyException("Failed to resume blocked actions"));
    }
  }
}
