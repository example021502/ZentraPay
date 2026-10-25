import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/models/siwe_message_params/siwe_message_params.dart';
import 'package:privy_flutter/src/models/wallet_login_metadata/wallet_login_metadata.dart';
import 'package:privy_flutter/src/modules/auth/auth_manager.dart';
import 'package:privy_flutter/src/modules/auth/link_type.dart';
import 'package:privy_flutter/src/modules/auth/unlink_type.dart';
import 'package:privy_flutter/src/modules/login_with_siwe/login_with_siwe.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Implementation of the `LoginWithSiwe` interface that interacts with the
/// native platform using method channels.
class RealLoginWithSiwe implements LoginWithSiwe {
  final MethodChannelHandler _channelHandler;
  final AuthManager _authManager;

  /// Constructor that initializes the method channel handler for communication.
  RealLoginWithSiwe(this._channelHandler, this._authManager);

  @override
  Future<Result<String>> generateMessage(SiweMessageParams params) async {
    LoggerService.debug(
        "Generating SIWE message for wallet: ${params.walletAddress}");

    try {
      final String? message = await _channelHandler.invokeMethod<String>(
        'generateSiweMessage',
        params.toJson(),
      );

      if (message != null) {
        LoggerService.debug("SIWE message generated successfully");
        return Success(message);
      } else {
        LoggerService.error("Failed to generate SIWE message: Empty response");
        return const Failure(PrivyException("Failed to generate SIWE message"));
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
    required SiweMessageParams params,
    WalletLoginMetadata? metadata,
  }) async {
    LoggerService.debug(
        "Attempting SIWE login for wallet: ${params.walletAddress}");

    if (message.isEmpty || signature.isEmpty) {
      LoggerService.error("login failed: Message or signature is empty");
      return const Failure(
          PrivyException("Message and signature are required"));
    }

    try {
      LoggerService.debug("Invoking method channel for siweLogin.");
      final Map<Object?, Object?>? responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'siweLogin',
        {
          'message': message,
          'signature': signature,
          ...params.toJson(),
          if (metadata != null) ...metadata.toJson(),
        },
      );

      LoggerService.debug("Received response from siweLogin: $responseData");

      // Convert response data into a `PrivyUser` instance.
      final convertedUser = safeCastToMap(responseData);

      LoggerService.debug(
          "Successfully logged in user via SIWE. User data: $convertedUser");
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
    required SiweMessageParams params,
    WalletLoginMetadata? metadata,
  }) async {
    LoggerService.debug(
        "Attempting SIWE link for wallet: ${params.walletAddress}");

    if (message.isEmpty || signature.isEmpty) {
      LoggerService.error("link failed: Message or signature is empty");
      return const Failure(
          PrivyException("Message and signature are required"));
    }

    return _authManager.link(SiweLink(
      message: message,
      signature: signature,
      siweParams: params.toJson(),
      metadata: metadata?.toJson(),
    ));
  }

  @override
  Future<Result<PrivyUser>> unlink({
    required String address,
  }) async {
    LoggerService.debug(
        "Attempting to unlink Ethereum wallet via SIWE: $address");

    return _authManager.unlink(SiweUnlink(address: address));
  }

  @override
  Future<Result<String>> generateSiweMessage(SiweMessageParams params) =>
      generateMessage(params);

  @override
  Future<Result<PrivyUser>> loginWithSiwe({
    required String message,
    required String signature,
    required SiweMessageParams params,
    WalletLoginMetadata? metadata,
  }) =>
      login(
        message: message,
        signature: signature,
        params: params,
        metadata: metadata,
      );

  @override
  Future<Result<PrivyUser>> linkWithSiwe({
    required String message,
    required String signature,
    required SiweMessageParams params,
    WalletLoginMetadata? metadata,
  }) =>
      link(
        message: message,
        signature: signature,
        params: params,
        metadata: metadata,
      );
}
