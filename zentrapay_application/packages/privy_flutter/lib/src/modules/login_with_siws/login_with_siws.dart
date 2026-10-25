import 'package:privy_flutter/src/core/privy_plug_in_module.dart';
import 'package:privy_flutter/src/models/siws_message_params/siws_message_params.dart';
import 'package:privy_flutter/src/models/wallet_login_metadata/wallet_login_metadata.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// Interface for handling Sign-In with Solana (SIWS) authentication flows.
abstract interface class LoginWithSiws extends PrivyPluginModule {
  /// Constructor that initializes the module with a method channel handler.
  LoginWithSiws(super.channelHandler);

  /// Generates a SIWS message for the user to sign to prove ownership of the wallet.
  ///
  /// [params] Specifies the app domain, app URI, and wallet address to build the SIWS message.
  /// Returns a `Result<String>` containing a unique SIWS message if successful, or a failure with an error.
  Future<Result<String>> generateMessage(SiwsMessageParams params);

  /// Logs in the user with the SIWS signature.
  ///
  /// [message] The SIWS message that was signed
  /// [signature] The SIWS signature generated from signing the message with the Solana wallet
  /// [params] The original SIWS message parameters
  /// [metadata] Optional additional metadata specifying wallet client and connector type
  /// Returns a `Result<PrivyUser>` containing the authenticated user if successful, or a failure with an error.
  Future<Result<PrivyUser>> login({
    required String message,
    required String signature,
    required SiwsMessageParams params,
    WalletLoginMetadata? metadata,
  });

  /// Links a Solana wallet to the currently authenticated user's account via SIWS.
  ///
  /// [message] The SIWS message that was signed
  /// [signature] The SIWS signature generated from signing the message with the Solana wallet
  /// [params] The original SIWS message parameters
  /// [metadata] Optional additional metadata specifying wallet client and connector type
  /// Returns a `Result<PrivyUser>` containing the updated user if successful, or a failure with an error.
  Future<Result<PrivyUser>> link({
    required String message,
    required String signature,
    required SiwsMessageParams params,
    WalletLoginMetadata? metadata,
  });

  /// Unlinks a Solana wallet from the currently authenticated user's account.
  ///
  /// [address] The Solana wallet address to unlink from the user
  /// Returns a `Result<PrivyUser>` containing the updated user if successful, or a failure with an error.
  Future<Result<PrivyUser>> unlink({
    required String address,
  });
}
