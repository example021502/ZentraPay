import 'dart:typed_data';

import 'package:privy_flutter/src/errors/privy_exception.dart';
import 'package:privy_flutter/src/helpers/safe_cast_to_map.dart';
import 'package:privy_flutter/src/logging/logger_service.dart';
import 'package:privy_flutter/src/models/embedded_ethereum_wallet/embedded_ethereum_wallet.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:privy_flutter/src/models/linked_accounts/linked_accounts.dart';
import 'package:privy_flutter/src/models/wallet_api_payload/wallet_api_payload.dart';
import 'package:privy_flutter/src/modules/mfa/mfa_method.dart';
import 'package:privy_flutter/src/modules/mfa/privy_user_mfa.dart';
import 'package:privy_flutter/src/modules/mfa/real_privy_user_mfa.dart';
import 'package:privy_flutter/src/modules/privy_user/privy_user.dart';
import 'package:privy_flutter/src/utils/method_channel_handler.dart';
import 'package:privy_flutter/src/utils/result.dart';

/// **Represents a Privy user implementation.**
class RealPrivyUser implements PrivyUser {
  final MethodChannelHandler _channelHandler = MethodChannelHandler();

  /// **Stored User Fields**
  @override
  String id;
  @override
  List<LinkedAccounts> linkedAccounts;
  @override
  List<EmbeddedEthereumWallet> embeddedEthereumWallets;
  @override
  List<EmbeddedSolanaWallet> embeddedSolanaWallets;

  // The identity token for this user, if configured in the Privy dashboard.
  @override
  String? identityToken;

  @override
  List<MfaMethod> mfaMethods;

  @override
  late final PrivyUserMfa mfa = RealPrivyUserMfa(_channelHandler);

  /// **Constructor**
  RealPrivyUser({
    required this.id,
    required this.linkedAccounts,
    this.identityToken,
    this.mfaMethods = const [],
  })  : embeddedEthereumWallets = _deriveEthereumWallets(linkedAccounts),
        embeddedSolanaWallets = _deriveSolanaWallets(linkedAccounts);

  /// **Factory constructor to create a `PrivyUser` from JSON**
  factory RealPrivyUser.fromJson(Map<String, dynamic> json) {
    return _parseJson(json, null);
  }

  /// **Refreshes user data from the server via native SDK**
  @override
  Future<Result<void>> refresh() async {
    LoggerService.debug("Refreshing user data from server.");

    try {
      final newData = await _channelHandler
          .invokeMethod<Map<Object?, Object?>>('refreshUser');

      if (newData != null) {
        final convertedUser = safeCastToMap(newData);
        final updatedUser = _parseJson(convertedUser, this);
        id = updatedUser.id;
        identityToken = updatedUser.identityToken;
        linkedAccounts = updatedUser.linkedAccounts;
        embeddedEthereumWallets = _deriveEthereumWallets(linkedAccounts);
        embeddedSolanaWallets = _deriveSolanaWallets(linkedAccounts);
        mfaMethods = updatedUser.mfaMethods;

        LoggerService.debug("User data successfully refreshed from server.");
      }
      return const Success(null);
    } catch (e) {
      LoggerService.error("Failed to refresh user data: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// **Extracted JSON parsing logic**
  static RealPrivyUser _parseJson(
      Map<String, dynamic> json, RealPrivyUser? existingUser) {
    return RealPrivyUser(
      id: json['id'] as String? ?? existingUser?.id ?? "",
      linkedAccounts: (json['linkedAccounts'] as List<dynamic>?)
              ?.map((account) => LinkedAccounts.fromJson(
                  Map<String, dynamic>.from(account as Map)))
              .where((account) =>
                  account is! UnknownAccount) // Filter out unknown accounts
              .toList() ??
          existingUser?.linkedAccounts ??
          [],
      identityToken:
          json['identityToken'] as String? ?? existingUser?.identityToken,
      mfaMethods: (json['mfaMethods'] as List<dynamic>?)
              ?.map((method) =>
                  MfaMethod.fromJson(Map<String, dynamic>.from(method as Map)))
              .toList() ??
          existingUser?.mfaMethods ??
          [],
    );
  }

  /// **Derives Ethereum wallets from `linkedAccounts`**
  static List<EmbeddedEthereumWallet> _deriveEthereumWallets(
      List<LinkedAccounts> linkedAccounts) {
    return linkedAccounts
        .whereType<
            EmbeddedEthereumWalletAccount>() // Filters only Ethereum wallet accounts
        .map((account) => EmbeddedEthereumWallet(
              id: account.id,
              address: account.address,
              chainId: account.chainId,
              recoveryMethod: account.recoveryMethod,
              hdWalletIndex: account.hdWalletIndex,
            ))
        .toList();
  }

  /// **Derives Solana wallets from `linkedAccounts`**
  static List<EmbeddedSolanaWallet> _deriveSolanaWallets(
      List<LinkedAccounts> linkedAccounts) {
    return linkedAccounts
        .whereType<
            EmbeddedSolanaWalletAccount>() // Filters only Solana wallet accounts
        .map((account) => EmbeddedSolanaWallet(
              id: account.id,
              address: account.address,
              chainId: account.chainId,
              recoveryMethod: account.recoveryMethod,
              hdWalletIndex: account.hdWalletIndex,
            ))
        .toList();
  }

  /// **Creates an Ethereum embedded wallet for the user**
  ///
  /// - [allowAdditional]: If true, allows creation of multiple wallets.
  /// - Returns a `Result<EmbeddedEthereumWallet>`.
  @override
  Future<Result<EmbeddedEthereumWallet>> createEthereumWallet(
      {bool allowAdditional = false}) async {
    LoggerService.debug(
        "Requesting Ethereum wallet creation (allowAdditional: $allowAdditional)");

    try {
      final Map<Object?, Object?>? walletData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'createEthereumWallet',
        {'allowAdditional': allowAdditional},
      );

      final convertedWallet = safeCastToMap(walletData);
      final wallet = EmbeddedEthereumWallet.fromJson(convertedWallet);
      await refresh();

      LoggerService.debug(
          "Ethereum wallet successfully created: ${wallet.address}");
      return Success(wallet);
    } catch (e) {
      LoggerService.error("Failed to create Ethereum wallet: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// **Creates a Solana embedded wallet for the user**
  @override
  Future<Result<EmbeddedSolanaWallet>> createSolanaWallet(
      {bool allowAdditional = false}) async {
    LoggerService.debug("Requesting Solana wallet creation.");

    try {
      final Map<Object?, Object?>? walletData =
          await _channelHandler.invokeMethod<Map<Object?, Object?>>(
        'createSolanaWallet',
        {'allowAdditional': allowAdditional},
      );

      final convertedWallet = safeCastToMap(walletData);
      final wallet = EmbeddedSolanaWallet.fromJson(convertedWallet);
      await refresh();

      LoggerService.debug(
          "Solana wallet successfully created: ${wallet.address}");
      return Success(wallet);
    } catch (e) {
      LoggerService.error("Failed to create Solana wallet: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// Generates a cryptographic signature for an API request payload.
  @override
  Future<Result<String>> generateAuthorizationSignature(
      WalletApiPayload payload) async {
    LoggerService.debug("Generating authorization signature.");

    try {
      final String? signature = await _channelHandler.invokeMethod<String>(
        'generateAuthorizationSignature',
        payload.toJson(),
      );

      if (signature == null) {
        throw const PrivyException(
            "No signature returned from native platform");
      }

      LoggerService.debug("Authorization signature generated successfully.");
      return Success(signature);
    } catch (e) {
      LoggerService.error("Failed to generate authorization signature: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// Generates a cryptographic signature for a pre-serialized binary payload.
  @override
  Future<Result<String>> generateAuthorizationSignatureFromBytes(
      Uint8List payload) async {
    LoggerService.debug("Generating authorization signature from bytes.");

    try {
      final String? signature = await _channelHandler.invokeMethod<String>(
        'generateAuthorizationSignatureFromBytes',
        payload,
      );

      if (signature == null) {
        throw const PrivyException(
            "No signature returned from native platform");
      }

      LoggerService.debug(
          "Authorization signature from bytes generated successfully.");
      return Success(signature);
    } catch (e) {
      LoggerService.error(
          "Failed to generate authorization signature from bytes: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// Migrates the user's wallets to TEE if needed.
  @override
  Future<Result<void>> migrateWalletsIfNeeded() async {
    LoggerService.debug("Requesting TEE wallet migration.");

    try {
      await _channelHandler.invokeMethod<void>('migrateWalletsIfNeeded');
      await refresh();
      LoggerService.debug("TEE wallet migration completed successfully.");
      return const Success(null);
    } catch (e) {
      LoggerService.error("Failed to migrate wallets: $e");
      return Failure(e.convertToPrivyException());
    }
  }

  /// Get the current access token.
  @override
  Future<Result<String>> getAccessToken() async {
    try {
      LoggerService.debug("Invoking getAccessToken method on native platform.");
      final token =
          await _channelHandler.invokeMethod<String>('getAccessToken');

      if (token == null) {
        throw const PrivyException("Error in getAccessToken: Token is null");
      }
      LoggerService.debug("Received access token: $token");
      return Success(token);
    } catch (e) {
      LoggerService.error("Error in getAccessToken: $e");
      return Failure(e.convertToPrivyException());
    }
  }
}
