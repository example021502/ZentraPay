import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/models/siws_message_params/siws_message_params.dart';
import 'package:privy_flutter/src/models/wallet_login_metadata/wallet_login_metadata.dart';
import 'package:privy_flutter/src/modules/auth/auth_manager.dart';
import 'package:privy_flutter/src/modules/auth/link_type.dart';
import 'package:privy_flutter/src/modules/auth/unlink_type.dart';
import 'package:privy_flutter/src/modules/login_with_siws/login_with_siws.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Implementation of the `LoginWithSiws` interface that interacts with the
/// native platform using method channels.
class RealLoginWithSiws implements LoginWithSiws {
  final MethodChannelHandler _channelHandler;
  final AuthManager _authManager;

  /// Constructor that initializes the method channel handler for communication.
  RealLoginWithSiws(this._channelHandler, this._authManager);

  @override
  Future<Result<String>> generateMessage(SiwsMessageParams params) async {
    LoggerService.debug(
        "Generating SIWS message for wallet: ${params.walletAddress}");

    try {
      final String? message = await _channelHandler.invokeMethod<String>(
        'generateSiwsMessage',
        params.toJson(),
      );

      if (message != null) {
        LoggerService.debug("SIWS message generated successfully");
        return Success(message);
      } else {
        LoggerService.error("Failed to generate SIWS message: Empty response");
        return const Failure(PrivyException("Failed to generate SIWS message"));
      }
    } catch (e) {
      LoggerService.error("generateMessage failed with exception: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  @override
  Future<Result<PrivyUser>> login({
    required String message,
    required String signature,
    required SiwsMessageParams params,
    WalletLoginMetadata? metadata,
  }) async {
    LoggerService.debug(
        "Attempting SIWS login for wallet: ${params.walletAddress}");

    if (message.isEmpty || signature.isEmpty) {
      LoggerService.error("login failed: Message or signature is empty");
      return const Failure(
          PrivyException("Message and signature are required"));
    }

    try {
      LoggerService.debug("Invoking method channel for siwsLogin.");
      final Map<Object?, Object?>? responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'siwsLogin',
        {
          'message': message,
          'signature': signature,
          ...params.toJson(),
          if (metadata != null) ...metadata.toJson(),
        },
      );

      LoggerService.debug("Received response from siwsLogin: $responseData");

      // Convert response data into a `PrivyUser` instance.
      final convertedUser = safeCastToMap(responseData);

      LoggerService.debug(
          "Successfully logged in user via SIWS. User data: $convertedUser");
      return Success(RealPrivyUser.fromJson(convertedUser));
    } catch (e) {
      LoggerService.error("login failed with exception: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  @override
  Future<Result<PrivyUser>> link({
    required String message,
    required String signature,
    required SiwsMessageParams params,
    WalletLoginMetadata? metadata,
  }) async {
    LoggerService.debug(
        "Attempting to link Solana wallet via SIWS: ${params.walletAddress}");

    if (message.isEmpty || signature.isEmpty) {
      LoggerService.error("link failed: Message or signature is empty");
      return const Failure(
          PrivyException("Message and signature are required"));
    }

    return _authManager.link(SiwsLink(
      message: message,
      signature: signature,
      siwsParams: params.toJson(),
      metadata: metadata?.toJson(),
    ));
  }

  @override
  Future<Result<PrivyUser>> unlink({
    required String address,
  }) async {
    LoggerService.debug(
        "Attempting to unlink Solana wallet via SIWS: $address");

    return _authManager.unlink(SiwsUnlink(address: address));
  }
}
