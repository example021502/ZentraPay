import 'dart:typed_data';

import 'package:privy_flutter/src/models/embedded_ethereum_wallet/embedded_ethereum_wallet.dart';
import 'package:privy_flutter/src/models/embedded_solana_wallet/embedded_solana_wallet.dart';
import 'package:privy_flutter/src/models/linked_accounts/linked_accounts.dart';
import 'package:privy_flutter/src/models/wallet_api_payload/wallet_api_payload.dart';
import 'package:privy_flutter/src/modules/mfa/mfa_method.dart';
import 'package:privy_flutter/src/modules/mfa/privy_user_mfa.dart';
import 'package:privy_flutter/src/utils/result.dart';

abstract class PrivyUser {
  /// Unique identifier for the user.
  String get id;

  /// List of linked accounts associated with the user.
  List<LinkedAccounts> get linkedAccounts;

  /// List of embedded Ethereum wallets associated with the user.
  List<EmbeddedEthereumWallet> get embeddedEthereumWallets;

  /// List of embedded Solana wallets associated with the user.
  List<EmbeddedSolanaWallet> get embeddedSolanaWallets;

  /// List of MFA methods enrolled for this user.
  List<MfaMethod> get mfaMethods;

  /// MFA operations for this user (totp, sms, passkey).
  PrivyUserMfa get mfa;

  /// Creates an Ethereum embedded wallet for the user.
  Future<Result<EmbeddedEthereumWallet>> createEthereumWallet(
      {bool allowAdditional = false});

  /// Creates a Solana embedded wallet for the user.
  Future<Result<EmbeddedSolanaWallet>> createSolanaWallet(
      {bool allowAdditional = false});

  /// Retrieves the current access token
  Future<Result<String>> getAccessToken();

  /// Retrieves the current refreshed user
  Future<Result<void>> refresh();

  /// Generates a cryptographic signature for an API request payload using the
  /// user's signing key. The returned signature can be included as the
  /// `privy-authorization-signature` header to authorize operations.
  Future<Result<String>> generateAuthorizationSignature(
      WalletApiPayload payload);

  /// Generates a cryptographic signature for a pre-serialized binary payload
  /// using the user's signing key.
  ///
  /// Unlike [generateAuthorizationSignature], this method skips JSON
  /// canonicalization and signs the raw bytes directly. Use this when you have
  /// already serialized and canonicalized your payload outside the SDK.
  Future<Result<String>> generateAuthorizationSignatureFromBytes(
      Uint8List payload);

  /// Migrates the user's wallets to TEE if needed.
  ///
  /// This is only required when `PrivyConfig.disableAutomaticMigration` is true.
  /// Returns success if migration completed or was not required.
  Future<Result<void>> migrateWalletsIfNeeded();

// The identity token for this user, if configured in the Privy dashboard.
  String? get identityToken;
}
