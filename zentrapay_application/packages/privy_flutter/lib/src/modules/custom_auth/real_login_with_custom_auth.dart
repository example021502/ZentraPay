import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/modules/custom_auth/login_with_custom_auth.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/modules/privy_user/real_privy_user.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Handles custom authentication operations.
class RealLoginWithCustomAuth implements LoginWithCustomAuth {
  final MethodChannelHandler _channelHandler;

  RealLoginWithCustomAuth(this._channelHandler);

  @override
  Future<Result<PrivyUser>> loginWithCustomAccessToken() async {
    try {
      // Pass token to the native side for login
      LoggerService.debug("Attempting login with custom access token.");
      final Map<Object?, Object?>? responseData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'loginWithCustomAccessToken',
      );

      LoggerService.debug(
          "Received response from loginWithCustomAccessToken: $responseData");

      final convertedUser = safeCastToMap(responseData);

      LoggerService.debug(
          "Successfully authenticated with custom access token. User data: $convertedUser");
      return Success(RealPrivyUser.fromJson(convertedUser));
    } catch (e) {
      LoggerService.error(
          "loginWithCustomAccessToken failed with exception: $e");
      return Failure(e.convertToPrivyException());
    }
  }
}
