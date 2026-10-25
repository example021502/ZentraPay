import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/models/siwe_message_params/siwe_message_params.dart';
import 'package:privy_flutter/src/models/wallet_login_metadata/wallet_login_metadata.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Interface for handling Sign-In with Ethereum (SIWE) authentication flows.
abstract interface class LoginWithSiwe extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  LoginWithSiwe(super.channelHandler);

  /// Generates a SIWE message for the user to sign to prove ownership of the wallet.
  ///
  /// [params] Specifies the app domain, app URI, chain ID, and wallet address to build the SIWE message.
  /// Returns a `Result<String>` containing a unique SIWE message if successful, or a failure with an error.
  Future<Result<String>> generateMessage(SiweMessageParams params);

  /// Logs in the user with the SIWE signature.
  ///
  /// [message] The SIWE message that was signed
  /// [signature] The SIWE signature generated from the EIP-191 personal sign request
  /// [params] The original SIWE message parameters
  /// [metadata] Optional additional metadata specifying wallet client and connector type
  /// Returns a `Result<PrivyUser>` containing the authenticated user if successful, or a failure with an error.
  Future<Result<PrivyUser>> login({
    required String message,
    required String signature,
    required SiweMessageParams params,
    WalletLoginMetadata? metadata,
  });

  /// Links a wallet to the current authenticated user using SIWE signature.
  ///
  /// [message] The SIWE message that was signed
  /// [signature] The SIWE signature generated from the EIP-191 personal sign request
  /// [params] The original SIWE message parameters
  /// [metadata] Optional additional metadata specifying wallet client and connector type
  /// Returns a `Result<PrivyUser>` containing the updated user if successful, or a failure with an error.
  Future<Result<PrivyUser>> link({
    required String message,
    required String signature,
    required SiweMessageParams params,
    WalletLoginMetadata? metadata,
  });

  /// Unlinks an Ethereum wallet from the currently authenticated user's account.
  ///
  /// [address] The Ethereum wallet address to unlink from the user
  /// Returns a `Result<PrivyUser>` containing the updated user if successful, or a failure with an error.
  Future<Result<PrivyUser>> unlink({
    required String address,
  });

  // Deprecated methods - kept for backward compatibility
  @Deprecated(
      'Use generateMessage() instead, which has identical functionality but simpler naming')
  Future<Result<String>> generateSiweMessage(SiweMessageParams params);

  @Deprecated(
      'Use login() instead, which has identical functionality but simpler naming')
  Future<Result<PrivyUser>> loginWithSiwe({
    required String message,
    required String signature,
    required SiweMessageParams params,
    WalletLoginMetadata? metadata,
  });

  @Deprecated(
      'Use link() instead, which has identical functionality but simpler naming')
  Future<Result<PrivyUser>> linkWithSiwe({
    required String message,
    required String signature,
    required SiweMessageParams params,
    WalletLoginMetadata? metadata,
  });
}
